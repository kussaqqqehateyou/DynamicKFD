//
//  utils.m
//  kfd
//
//  Created by Seo Hyun-gyu on 2023/07/30.
//

#import <Foundation/Foundation.h>
#import "vnode.h"
#import "krw.h"
#import "helpers.h"

uint64_t createFolderAndRedirect(uint64_t vnode) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
    uint64_t orig_to_v_data = funVnodeRedirectFolderFromVnode(mntPath.UTF8String, vnode);
    
    return orig_to_v_data;
}

uint64_t UnRedirectAndRemoveFolder(uint64_t orig_to_v_data) {
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    funVnodeUnRedirectFolder(mntPath.UTF8String, orig_to_v_data);
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    
    return 0;
}

//- (void)createPlistAtURL:(NSURL *)url height:(NSInteger)height width:(NSInteger)width error:(NSError **)error {
//    NSDictionary *dictionary = @{
//        @"canvas_height": @(height),
//        @"canvas_width": @(width)
//    };
//    BOOL success = [dictionary writeToURL:url atomically:YES];
//    if (!success) {
//        NSDictionary *userInfo = @{
//            NSLocalizedDescriptionKey: @"Failed to write property list to URL.",
//            NSLocalizedFailureReasonErrorKey: @"Error occurred while writing the property list.",
//            NSFilePathErrorKey: url.path
//        };
//        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
//    }
//}
int createPlistAtPath(NSString *path, NSInteger height, NSInteger width) {
    NSDictionary *dictionary = @{
        @"canvas_height": @(height),
        @"canvas_width": @(width)
    };
    
    BOOL success = [dictionary writeToFile:path atomically:YES];
    if (!success) {
        printf("[-] Failed createPlistAtPath.\n");
        return -1;
    }
    
    return 0;
}

int createPlistAtPath_dynamic(NSString *path, NSInteger SubType) {
    NSDictionary *dictionary = @{
        @"CacheExtra": @{
            @"oPeik/9e8lQWMszEjbPzng": @{
                @"ArtworkDeviceSubType": @(SubType)
            }
        }
    };
    
    BOOL success = [dictionary writeToFile:path atomically:YES];
    if (!success) {
        printf("[-] Failed createPlistAtPath.\n");
        return -1;
    }
    
    return 0;
}

#include "offsets.h"

uint64_t xResolution = 4368;
uint64_t yResolution = 2015;

int ResSet16(void) {
    
    _offsets_init();
    
    //1. Create /var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist
    uint64_t var_vnode = getVnodeVar(); 
    printf("found var vnode\n");
    uint64_t var_tmp_vnode = findChildVnodeByVnode(var_vnode, "tmp");
    printf("found var tmp vnode\n");
    printf("[i] /var/tmp vnode: 0x%llx\n", var_tmp_vnode);
    uint64_t orig_to_v_data = createFolderAndRedirect(var_tmp_vnode);
    
    printf("created var vnode folder\n");
    
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    //iPhone 14 Pro Max Resolution
    createPlistAtPath([mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"], xResolution, yResolution);
    
    UnRedirectAndRemoveFolder(orig_to_v_data);
    
    
    //2. Create symbolic link /var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist -> /var/mobile/Library/Preferences/com.apple.iokit.IOMobileGraphicsFamily.plist
    uint64_t preferences_vnode = getVnodePreferences();
    orig_to_v_data = createFolderAndRedirect(preferences_vnode);

    remove([mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"].UTF8String);
    printf("symlink ret: %d\n", symlink("/var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist", [mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"].UTF8String));
    UnRedirectAndRemoveFolder(orig_to_v_data);
        
    //3. xpc restart
    do_kclose(_kfd);
    sleep(1);
    xpc_crasher("com.apple.cfprefsd.daemon");
    xpc_crasher("com.apple.backboard.TouchDeliveryPolicyServer");
    
    return 0;
}

int DynamicKFD(NSInteger SubType, NSInteger width) {
    
    _offsets_init();
    
    //1. Create /var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist
    uint64_t var_vnode = getVnodeVar();
    printf("found var vnode\n");
    uint64_t var_tmp_vnode = findChildVnodeByVnode(var_vnode, "tmp");
    printf("found var tmp vnode\n");
    printf("[i] /var/tmp vnode: 0x%llx\n", var_tmp_vnode);
    uint64_t orig_to_v_data = createFolderAndRedirect(var_tmp_vnode);
    
    printf("created var vnode folder\n");
    
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    [[NSFileManager defaultManager] removeItemAtPath:mntPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:mntPath withIntermediateDirectories:NO attributes:nil error:nil];
    
    //iPhone 14 Pro Max System
    createPlistAtPath_dynamic([mntPath stringByAppendingString:@"/com.apple.MobileGestalt.plist"], SubType);
    
    UnRedirectAndRemoveFolder(orig_to_v_data);
    
    
    //2. Create symbolic link /var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist -> /var/mobile/Library/Preferences/com.apple.iokit.IOMobileGraphicsFamily.plist
    uint64_t gestalt_vnode = getVnodegestalt();
    //uint64_t gestalt_vnode = findChildVnodeByVnode(gestalt_vnode, "com.apple.MobileGestalt.plist");
    orig_to_v_data = createFolderAndRedirect(gestalt_vnode);

    funVnodeOverwriteFile("", "");
    remove([mntPath stringByAppendingString:@"/com.apple.MobileGestalt.plist"].UTF8String);
    printf("symlink ret: %d\n", symlink("/var/tmp/com.apple.MobileGestalt.plist", [mntPath stringByAppendingString:@"/com.apple.MobileGestalt.plist"].UTF8String));
    UnRedirectAndRemoveFolder(orig_to_v_data);
    
    //iPhone 14 Pro Max Resolution
    createPlistAtPath([mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"], SubType, width);
    
    UnRedirectAndRemoveFolder(orig_to_v_data);
    
    
    //3. Create symbolic link /var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist -> /var/mobile/Library/Preferences/com.apple.iokit.IOMobileGraphicsFamily.plist
    uint64_t preferences_vnode = getVnodePreferences();
    orig_to_v_data = createFolderAndRedirect(preferences_vnode);

    remove([mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"].UTF8String);
    printf("symlink ret: %d\n", symlink("/var/tmp/com.apple.iokit.IOMobileGraphicsFamily.plist", [mntPath stringByAppendingString:@"/com.apple.iokit.IOMobileGraphicsFamily.plist"].UTF8String));
    UnRedirectAndRemoveFolder(orig_to_v_data);
    
    //4. xpc restart
    do_kclose(_kfd);
    sleep(1);
    xpc_crasher("com.apple.mobilegestalt.xpc");
    xpc_crasher("com.apple.cfprefsd.daemon");
    xpc_crasher("com.apple.backboard.TouchDeliveryPolicyServer");
    
    return 0;
}

int removeSMSCache(void) {
    uint64_t library_vnode = getVnodeLibrary();
    uint64_t sms_vnode = findChildVnodeByVnode(library_vnode, "SMS");
    
    //retry find SMS vnode
    while(1) {
        if(sms_vnode != 0)
            break;
        library_vnode = getVnodeLibrary();
        sms_vnode = findChildVnodeByVnode(library_vnode, "SMS");
    }
    printf("[i] /var/mobile/Library/SMS vnode: 0x%llx\n", sms_vnode);
    
    uint64_t orig_to_v_data = createFolderAndRedirect(sms_vnode);
    
    NSString *mntPath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), @"/Documents/mounted"];
    
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/SMS directory list: %@", dirs);
    
    remove([mntPath stringByAppendingString:@"/com.apple.messages.geometrycache_v7.plist"].UTF8String);
    
    dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:mntPath error:NULL];
    NSLog(@"/var/mobile/Library/SMS directory list: %@", dirs);
    
    UnRedirectAndRemoveFolder(orig_to_v_data);
    
    return 0;
}
