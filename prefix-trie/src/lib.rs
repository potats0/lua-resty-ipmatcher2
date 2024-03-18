#![allow(clippy::collapsible_else_if)]
// #![deny(missing_docs)]

mod fmt;
mod prefix;
#[cfg(feature = "serde")]
mod serde;
#[cfg(test)]
#[cfg(feature = "ipnet")]
mod test;

pub mod map;
pub mod set;

use std::{
    ffi::{c_char, c_int, c_void},
    net::Ipv4Addr,
};

use ipnet::Ipv4Net;
pub use map::PrefixMap;
pub use prefix::Prefix;
pub use set::PrefixSet;

#[inline(always)]
pub(crate) fn to_right<P: Prefix>(branch_p: &P, child_p: &P) -> bool {
    child_p.is_bit_set(branch_p.prefix_len())
}

// 0代表没有，1代表黑名单，2代表白名单
// new方法, 返回一个
// get方法 这里只会输入Host主机
// add方法
// remove方法
// alter 修改动作
// free 释放

#[no_mangle]
pub extern "C" fn new_prefix_trie() -> *mut c_void {
    let prefix_map: Box<PrefixMap<Ipv4Net, u32>> = Box::new(PrefixMap::<Ipv4Net, u32>::new());
    // 获取 Box 内部的指针并转换为 *mut c_void 类型
    let ptr: *mut c_void = Box::into_raw(prefix_map) as *mut c_void;

    ptr
}

#[no_mangle]
pub extern "C" fn free_prefix_trie(prefix_map_ptr: *mut c_void) {
    let prefix_map_raw: *mut PrefixMap<Ipv4Net, u32> =
        prefix_map_ptr as *mut PrefixMap<Ipv4Net, u32>;

    // 将 *mut PrefixMap 转换为 Box<PrefixMap<Ipv4Net, u32>> 类型
    let _prefix_map_box: Box<PrefixMap<Ipv4Net, u32>> = unsafe { Box::from_raw(prefix_map_raw) };
}

/* 返回0 代表正常
1 ip地址解析出错
*/
#[no_mangle]
pub extern "C" fn insert(
    prefix_map_ptr: *mut c_void,
    ipv4_addr: u32,
    netmask: u8,
    action: u8,
) -> c_int {
    // 转换为 *mut PrefixMap<Ipv4Net, u32> 类型
    let prefix_map_raw: *mut PrefixMap<Ipv4Net, u32> =
        prefix_map_ptr as *mut PrefixMap<Ipv4Net, u32>;

    // 将 *mut PrefixMap 转换为 Box<PrefixMap<Ipv4Net, u32>> 类型
    let mut prefix_map_box: Box<PrefixMap<Ipv4Net, u32>> = unsafe { Box::from_raw(prefix_map_raw) };

    let ipv4_addr = match Ipv4Net::new(Ipv4Addr::from(ipv4_addr), netmask) {
        Ok(addr) => addr,
        Err(_) => return 1,
    };
    prefix_map_box.insert(ipv4_addr, action as u32);

    Box::into_raw(prefix_map_box) as *mut c_void;
    return 0;
}

#[no_mangle]
pub extern "C" fn get(prefix_map_ptr: *mut c_void, ipv4_addr: u32, netmask: u8) -> c_char {
    // 转换为 *mut PrefixMap<Ipv4Net, u32> 类型
    let prefix_map_raw: *mut PrefixMap<Ipv4Net, u32> =
        prefix_map_ptr as *mut PrefixMap<Ipv4Net, u32>;

    // 将 *mut PrefixMap 转换为 Box<PrefixMap<Ipv4Net, u32>> 类型
    let prefix_map_box: Box<PrefixMap<Ipv4Net, u32>> = unsafe { Box::from_raw(prefix_map_raw) };

    let ipv4_addr = match Ipv4Net::new(Ipv4Addr::from(ipv4_addr), netmask) {
        Ok(addr) => addr,
        Err(_) => return 1,
    };

    let return_action: c_char;
    match prefix_map_box.get_lpm(&ipv4_addr) {
        Some(action) => return_action = (*action.1).try_into().unwrap(),
        None => return_action = 0,
    }

    Box::into_raw(prefix_map_box) as *mut c_void;
    return_action
}

#[no_mangle]
pub extern "C" fn remove(prefix_map_ptr: *mut c_void, ipv4_addr: u32, netmask: u8) {
    // 转换为 *mut PrefixMap<Ipv4Net, u32> 类型
    let prefix_map_raw: *mut PrefixMap<Ipv4Net, u32> =
        prefix_map_ptr as *mut PrefixMap<Ipv4Net, u32>;

    // 将 *mut PrefixMap 转换为 Box<PrefixMap<Ipv4Net, u32>> 类型
    let mut prefix_map_box: Box<PrefixMap<Ipv4Net, u32>> = unsafe { Box::from_raw(prefix_map_raw) };

    let prefix = match Ipv4Net::new(Ipv4Addr::from(ipv4_addr), netmask) {
        Ok(addr) => addr,
        Err(_) => return,
    };

    prefix_map_box.remove(&prefix);

    Box::into_raw(prefix_map_box) as *mut c_void;
}

#[cfg(test)]
mod tests {

    use super::*;

    #[test]
    fn test_1() {
        let map_ptr: *mut c_void = new_prefix_trie();
        insert(map_ptr, 3232235776, 24, 1);
        let _a = get(map_ptr, 3232235777, 32);
        free_prefix_trie(map_ptr);
    }

    #[test]
    fn test_2() {
        let map_ptr: *mut c_void = new_prefix_trie();
        insert(map_ptr, 3232235776, 24, 1);
        remove(map_ptr, 3232235776, 24);
        assert_eq!(get(map_ptr, 3232235777, 32), 0);
    }
}
