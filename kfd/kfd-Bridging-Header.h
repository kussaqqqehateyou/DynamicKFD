/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#include "libkfd.h"
#include "fun.h"
#include <Foundation/Foundation.h>
#include "krw.h"
#include "helpers.h"

uint64_t funVnodeOverwrite2(const char* to, const char* from);
void grant_full_disk_access(void (^completion)(NSError* _Nullable));

void respringFrontboard(void) {
  xpc_crasher("com.apple.frontboard.systemappservices");
}

void respringBackboard(void) {
  xpc_crasher("com.apple.backboard.TouchDeliveryPolicyServer");
}

void killMobileGestalt(void) {
  xpc_crasher("com.apple.mobilegestalt.xpc");
}

int ResSet16(void);
int DynamicKFD(void);


uint64_t xResolution;
uint64_t yResolution;

#include "vnode.h"

uint64_t UnRedirectAndRemoveFolder(uint64_t orig_to_v_data);

uint64_t createFolderAndRedirect(uint64_t vnode);

int createPlistAtPath(NSString *path, NSInteger height, NSInteger width);
