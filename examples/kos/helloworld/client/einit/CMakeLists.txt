# © 2022 AO Kaspersky Lab. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

project (einit)

# Tools for using NK parser.
include (platform/image)

# Set compile flags.
project_header_default ("STANDARD_GNU_11:YES" "STRICT_WARNINGS:NO")

# Choose secure (ON) or insecure (OFF) connection for gRPC server.
option (USE_SECURE_CONNECTION "Use secure connection for gRPC")

# Define the ENTITIES variable with a list of entities.
set (ENTITIES
        GreeterClient
        ${precompiled_vfsVfsRamFs}
        ${precompiled_vfsVfsNet}
        ${rump_DHCPCD_ENTITY})
       
set (EXTRA_CONNECTIONS "\
  - target: kl.VfsNet
    id: kl.VfsNet
  - target: kl.VfsRamFs
    id: kl.VfsRamFs")

set_target_properties (${rump_DHCPCD_ENTITY} PROPERTIES
    DEPENDS_ON_ENTITY ""
    EXTRA_CONNECTIONS ${EXTRA_CONNECTIONS}
    EXTRA_ENV "\
    VFS_FILESYSTEM_BACKEND: client{fs->net}:kl.VfsRamFs
    VFS_NETWORK_BACKEND: client:kl.VfsNet"
    EXTRA_ARGS "\
    - '-4'
    - -f
    - /etc/dhcpcd.conf")

set_target_properties(${precompiled_vfsVfsRamFs} PROPERTIES
    EXTRA_ARGS "\
    - -l
    - devfs /dev devfs 0
    - -l
    - romfs /romfs romfs 0")

if (USE_SECURE_CONNECTION)
    set_target_properties(GreeterClient PROPERTIES
            EXTRA_ARGS "- --secure")
endif()

# Make the disk image
add_custom_target (ramdisk0.img
        COMMAND $ENV{SDK_PREFIX}/common/prepare_hdd_img.sh
        -d ${CMAKE_SOURCE_DIR}/resources/ramfs -f ext4 -s 32
        -img ramdisk0.img)

set (FILES ${CMAKE_BINARY_DIR}/einit/ramdisk0.img)

if (USE_SECURE_CONNECTION)

    list(APPEND FILES ${SSL_SERTIFICATE_DIR}/ca.pem)

endif ()

# KasperskyOS image for target hardware platform.
build_kos_hw_image (kos-image
        EINIT_ENTITY EinitHw
        CONNECTIONS_CFG "src/init.yaml.in"
        SECURITY_PSL "src/security.psl"
        ${ENTITIES}
        ${FILES})

add_dependencies (kos-image ramdisk0.img)

# KasperskyOS image for QEMU with simulation targets (sim, gdbsim, gdb).
build_kos_qemu_image (kos-qemu-image
        EINIT_ENTITY EinitQemu
        CONNECTIONS_CFG "src/init.yaml.in"
        SECURITY_PSL "src/security.psl"
        IMAGE_FILES ${ENTITIES}
        ${FILES})

add_dependencies (kos-qemu-image ramdisk0.img)
