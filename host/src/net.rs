use crate::config::Config;
use serde::Serialize;
use std::net::IpAddr;

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

/// Addresses a phone could use to reach this PC.
pub fn addresses() -> Vec<Addr> {
    let mut out = Vec::new();
    if let Ok(ifaces) = if_addrs::get_if_addrs() {
        for i in ifaces {
            if i.is_loopback() {
                continue;
            }
            match i.ip() {
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
