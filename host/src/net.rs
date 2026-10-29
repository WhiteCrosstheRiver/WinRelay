use crate::config::Config;
use serde::Serialize;
use std::net::{IpAddr, Ipv4Addr, Ipv6Addr};

#[derive(Serialize, Clone)]
pub struct Addr {
    pub kind: &'static str,
    pub ip: String,
}

pub fn host_name() -> String {
    std::env::var("COMPUTERNAME").unwrap_or_else(|_| "This PC".into())
}

fn is_global_v6(ip: &std::net::Ipv6Addr) -> bool {
    // 2000::/3 is the global unicast range.
    (ip.segments()[0] & 0xe000) == 0x2000
}

/// Adapters we must never hand to a phone: VMware, Hyper-V/WSL, VPNs,
/// ZeroTier... On a developer PC these enumerate first and would put a
/// dead address into the pairing QR code.
const VIRTUAL_KEYWORDS: &[&str] = &[
    "vmware", "virtual", "hyper-v", "vethernet", "wsl", "tap", "tun", "zerotier",
    "tailscale", "openvpn", "wireguard", "loopback", "npcap", "vpn", "easyconnect",
    "pangp", "clash", "bluetooth", "wi-fi direct", "wan miniport",
];

fn looks_virtual(name: &str, desc: &str) -> bool {
    let hay = format!("{} {}", name, desc).to_lowercase();
    VIRTUAL_KEYWORDS.iter().any(|k| hay.contains(k))
}

/// Walk the adapter list the Windows way so we can tell real NICs from
/// virtual ones, and skip privacy-temporary IPv6 addresses (they churn and
/// are not DNS-eligible; the permanent one is what belongs in a QR code).
fn adapter_addrs() -> Vec<(bool, Vec<IpAddr>)> {
    use windows::Win32::NetworkManagement::IpHelper::{
        GetAdaptersAddresses, GET_ADAPTERS_ADDRESSES_FLAGS, IP_ADAPTER_ADDRESSES_LH,
    };
    use windows::Win32::Networking::WinSock::SOCKADDR;

    // GAA_FLAG_SKIP_ANYCAST | SKIP_MULTICAST | SKIP_DNS_SERVER
    const FLAGS: GET_ADAPTERS_ADDRESSES_FLAGS = GET_ADAPTERS_ADDRESSES_FLAGS(0x2 | 0x4 | 0x8);
    const AF_UNSPEC: u32 = 0;
    // IP_ADAPTER_ADDRESS_DNS_ELIGIBLE (Flags sits at offset 4, next to Len at 0)
    const DNS_ELIGIBLE: u32 = 0x1;

    /// Reads the address bytes straight out of the socket address so we don't
    /// depend on the IN_ADDR/IN6_ADDR union shapes: v4 lives at offset 4,
    /// v6 at offset 8 of the respective sockaddr structs.
    fn sock_ip(sa: *const SOCKADDR) -> Option<IpAddr> {
        unsafe {
            let fam = (*sa).sa_family.0 as u32;
            let p = sa as *const u8;
            match fam {
                2 => Some(IpAddr::V4(Ipv4Addr::new(*p.add(4), *p.add(5), *p.add(6), *p.add(7)))),
                23 => {
                    let mut b = [0u8; 16];
                    for (i, byte) in b.iter_mut().enumerate() {
                        *byte = *p.add(8 + i);
                    }
                    Some(IpAddr::V6(Ipv6Addr::from(b)))
                }
                _ => None,
            }
        }
    }

    unsafe {
        let mut size = 0u32;
        let _ = GetAdaptersAddresses(AF_UNSPEC, FLAGS, None, None, &mut size);
        if size == 0 {
            return Vec::new();
        }
        let mut buf = vec![0u8; size as usize];
        let head = buf.as_mut_ptr() as *mut IP_ADAPTER_ADDRESSES_LH;
        if GetAdaptersAddresses(AF_UNSPEC, FLAGS, None, Some(head), &mut size) != 0 {
            return Vec::new();
        }

        let mut out: Vec<(bool, Vec<IpAddr>)> = Vec::new();
        let mut cur = head;
        while !cur.is_null() {
            let a = &*cur;
            // 1 = IfOperStatusUp
            let up = a.OperStatus.0 == 1;
            // 6 = ethernet, 71 = wifi; anything else (tunnels, miniports,
            // propVirtuals) is not a NIC a phone could reach us on.
            let nic = a.IfType == 6 || a.IfType == 71;
            let name = a.FriendlyName.to_string().unwrap_or_default();
            let desc = a.Description.to_string().unwrap_or_default();
            let physical = up && nic && !looks_virtual(&name, &desc);

            let mut ips = Vec::new();
            let mut u = a.FirstUnicastAddress;
            while !u.is_null() {
                let ua = &*u;
                // IP_ADAPTER_UNICAST_ADDRESS: Len at offset 0, Flags at 4.
                let flags = (ua as *const _ as *const u32).add(1).read();
                let v6_permanent = (flags & DNS_ELIGIBLE) != 0;
                let sa = ua.Address.lpSockaddr;
                if !sa.is_null() {
                    if let Some(ip) = sock_ip(sa) {
                        match ip {
                            IpAddr::V4(v4) if !v4.is_loopback() && !v4.is_link_local() => ips.push(IpAddr::V4(v4)),
                            IpAddr::V6(v6) if is_global_v6(&v6) && v6_permanent => ips.push(IpAddr::V6(v6)),
                            _ => {}
                        }
                    }
                }
                u = ua.Next;
            }
            if !ips.is_empty() {
                out.push((physical, ips));
            }
            cur = a.Next;
        }
        // Physical NICs first so the pairing link prefers them.
        out.sort_by_key(|(physical, _)| !*physical);
        out
    }
}

/// Addresses a phone could use to reach this PC. Global IPv6 wins over LAN
/// IPv4 inside each class; virtual adapters are listed but marked so they
/// never end up in the pairing link.
pub fn addresses() -> Vec<Addr> {
    let mut out = Vec::new();
    for (physical, ips) in adapter_addrs() {
        if !physical {
            continue;
        }
        for ip in ips {
            match ip {
                IpAddr::V4(v4) if v4.is_private() => out.push(Addr { kind: "Home network", ip: v4.to_string() }),
                IpAddr::V6(v6) if is_global_v6(&v6) => out.push(Addr { kind: "Internet (IPv6)", ip: v6.to_string() }),
                _ => {}
            }
        }
    }
    out
}

/// Loopback, private IPv4, link-local, or IPv6 unique-local.
pub fn is_local(ip: IpAddr) -> bool {
    match ip.to_canonical() {
        IpAddr::V4(v4) => v4.is_loopback() || v4.is_private() || v4.is_link_local(),
        IpAddr::V6(v6) => {
            let s0 = v6.segments()[0];
            v6.is_loopback() || (s0 & 0xfe00) == 0xfc00 || (s0 & 0xffc0) == 0xfe80
        }
    }
}

/// The address written into the pairing link.
pub fn link_host(cfg: &Config, addrs: &[Addr]) -> String {
    if cfg.allow_internet {
        if !cfg.ddns_host.trim().is_empty() {
            return cfg.ddns_host.trim().to_string();
        }
        if let Some(a) = addrs.iter().find(|a| a.kind.starts_with("Internet")) {
            return a.ip.clone();
        }
    }
    addrs
        .iter()
        .find(|a| a.kind == "Home network")
        .map(|a| a.ip.clone())
        .unwrap_or_else(|| "localhost".into())
}

pub fn pair_link(host: &str, port: u16, token: &str, name: &str) -> String {
    format!("winrelay://pair?h={}&p={}&k={}&n={}", enc(host), port, enc(token), enc(name))
}

fn enc(s: &str) -> String {
    s.bytes()
        .map(|b| match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'.' | b'_' | b'~' => (b as char).to_string(),
            _ => format!("%{:02X}", b),
        })
        .collect()
}
