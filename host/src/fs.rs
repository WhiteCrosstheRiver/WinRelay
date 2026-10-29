//! File access for the phone: list folders, create folders, delete to the
//! Recycle Bin, and chunked upload/download over the WebSocket.
//! Only paired phones ever get here (same gate as everything else).

use serde::Serialize;
use std::fs;
use std::path::Path;
use std::time::UNIX_EPOCH;
use windows::core::PCWSTR;
use windows::Win32::Foundation::HWND;
use windows::Win32::UI::Shell::{SHFileOperationW, SHFILEOPSTRUCTW};

const CHUNK: usize = 256 * 1024;

#[derive(Serialize, Clone, Debug)]
pub struct FsItem {
    pub name: String,
    pub dir: bool,
    pub size: u64,
    /// Unix seconds; 0 for drives.
    pub modified: u64,
}

/// Drive letters as the root view ("This PC").
pub fn drives() -> Vec<FsItem> {
    let mut out = Vec::new();
    for c in b'A'..=b'Z' {
        let letter = c as char;
        let root = format!("{letter}:\\");
        if Path::new(&root).exists() {
            out.push(FsItem { name: format!("{letter}:"), dir: true, size: 0, modified: 0 });
        }
    }
    out
}

/// Windows treats "C:" as the drive's *current directory*, not its root.
/// The phone sends bare drive letters, so normalise them here.
fn norm(path: &str) -> String {
    let t = path.trim();
    if t.len() == 2 && t.as_bytes()[1] == b':' {
        format!("{t}\\")
    } else {
        t.to_string()
    }
}

pub fn list(path: &str) -> anyhow::Result<Vec<FsItem>> {
    let path = &norm(path);
    if path.is_empty() {
        return Ok(drives());
    }
    let mut out = Vec::new();
    for e in fs::read_dir(path)? {
        let Ok(entry) = e else { continue };
        let Ok(meta) = entry.metadata() else { continue };
        let name = entry.file_name().to_string_lossy().to_string();
        let dir = meta.is_dir();
        let modified = meta
            .modified()
            .ok()
            .and_then(|t| t.duration_since(UNIX_EPOCH).ok())
            .map(|d| d.as_secs())
            .unwrap_or(0);
        out.push(FsItem { name, dir, size: if dir { 0 } else { meta.len() }, modified });
    }
    out.sort_by(|a, b| b.dir.cmp(&a.dir).then(a.name.to_lowercase().cmp(&b.name.to_lowercase())));
    Ok(out)
}

pub fn mkdir(path: &str) -> anyhow::Result<()> {
    fs::create_dir_all(norm(path))?;
    Ok(())
}

/// Moves the path to the Recycle Bin instead of erasing it.
pub fn delete_to_trash(path: &str) -> anyhow::Result<()> {
    let mut from: Vec<u16> = norm(path).encode_utf16().collect();
    from.push(0);
    from.push(0); // pFrom is a double-null-terminated list
    let mut op = SHFILEOPSTRUCTW {
        hwnd: HWND::default(),
        wFunc: 3, // FO_DELETE
        pFrom: PCWSTR(from.as_ptr()),
        pTo: PCWSTR::null(),
        fFlags: 0x40 | 0x10 | 0x4, // FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_SILENT
        fAnyOperationsAborted: windows::Win32::Foundation::BOOL::default(),
        hNameMappings: std::ptr::null_mut(),
        lpszProgressTitle: PCWSTR::null(),
    };
    let code = unsafe { SHFileOperationW(&mut op) };
    if code != 0 {
        anyhow::bail!("Delete failed (code {code}).");
    }
    if op.fAnyOperationsAborted.as_bool() {
        anyhow::bail!("Delete was cancelled.");
    }
    Ok(())
}

/// Sanity gate shared by upload targets and downloads: refuse obviously
/// dangerous system paths for writes.
pub fn writable(path: &str) -> anyhow::Result<()> {
    let p = norm(path).to_lowercase();
    const BLOCKED: &[&str] = &["\\windows\\", "\\program files", "\\programdata\\"];
    if BLOCKED.iter().any(|b| p.contains(b)) && !p.contains("\\windows\\temp") {
        anyhow::bail!("Writing into system folders is not allowed.");
    }
    Ok(())
}

pub fn read_chunk(path: &str, offset: u64, len: usize) -> anyhow::Result<(Vec<u8>, bool)> {
    use std::io::{Read, Seek, SeekFrom};
    let mut f = fs::File::open(norm(path))?;
    f.seek(SeekFrom::Start(offset))?;
    let mut buf = vec![0u8; len];
    let mut read = 0usize;
    loop {
        let n = f.read(&mut buf[read..])?;
        if n == 0 {
            break;
        }
        read += n;
        if read == len {
            break;
        }
    }
    buf.truncate(read);
    let total = f.metadata()?.len();
    let done = offset + read as u64 >= total;
    Ok((buf, done))
}

pub fn total_size(path: &str) -> anyhow::Result<u64> {
    Ok(fs::metadata(norm(path))?.len())
}

pub const CHUNK_SIZE: usize = CHUNK;
