


----------------------------------------------------------------------------------------------------------------------



sudo apt install gparted flex automake autoconf build-essential libncurses5-dev libncursesw5-dev libtool libevent-dev libssl-dev wget curl ssh net-tools pkg-config bash binutils bison coreutils diffutils findutils gawk gcc grep gzip m4 make patch perl python3 sed tar texinfo xz-utils g++ -y


----------------------------------------------------------------------------------------------------------------------


sudo dpkg-reconfigure dash

----------------------------------------------------------------------------------------------------------------------



cat > version-check.sh << "EOF"
#!/bin/bash
# A script to list version numbers of critical development tools

# If you have tools installed in other directories, adjust PATH here AND
# in ~lfs/.bashrc (section 4.4) as well.

LC_ALL=C 
PATH=/usr/bin:/bin

bail() { echo "FATAL: $1"; exit 1; }
grep --version > /dev/null 2> /dev/null || bail "grep does not work"
sed '' /dev/null || bail "sed does not work"
sort   /dev/null || bail "sort does not work"

ver_check()
{
   if ! type -p $2 &>/dev/null
   then 
     echo "ERROR: Cannot find $2 ($1)"; return 1; 
   fi
   v=$($2 --version 2>&1 | grep -E -o '[0-9]+\.[0-9\.]+[a-z]*' | head -n1)
   if printf '%s\n' $3 $v | sort --version-sort --check &>/dev/null
   then 
     printf "OK:    %-9s %-6s >= $3\n" "$1" "$v"; return 0;
   else 
     printf "ERROR: %-9s is TOO OLD ($3 or later required)\n" "$1"; 
     return 1; 
   fi
}

ver_kernel()
{
   kver=$(uname -r | grep -E -o '^[0-9\.]+')
   if printf '%s\n' $1 $kver | sort --version-sort --check &>/dev/null
   then 
     printf "OK:    Linux Kernel $kver >= $1\n"; return 0;
   else 
     printf "ERROR: Linux Kernel ($kver) is TOO OLD ($1 or later required)\n" "$kver"; 
     return 1; 
   fi
}

# Coreutils first because --version-sort needs Coreutils >= 7.0
ver_check Coreutils      sort     8.1 || bail "Coreutils too old, stop"
ver_check Bash           bash     3.2
ver_check Binutils       ld       2.13.1
ver_check Bison          bison    2.7
ver_check Diffutils      diff     2.8.1
ver_check Findutils      find     4.2.31
ver_check Gawk           gawk     4.0.1
ver_check GCC            gcc      5.2
ver_check "GCC (C++)"    g++      5.2
ver_check Grep           grep     2.5.1a
ver_check Gzip           gzip     1.3.12
ver_check M4             m4       1.4.10
ver_check Make           make     4.0
ver_check Patch          patch    2.5.4
ver_check Perl           perl     5.8.8
ver_check Python         python3  3.4
ver_check Sed            sed      4.1.5
ver_check Tar            tar      1.22
ver_check Texinfo        texi2any 5.0
ver_check Xz             xz       5.0.0
ver_kernel 4.19

if mount | grep -q 'devpts on /dev/pts' && [ -e /dev/ptmx ]
then echo "OK:    Linux Kernel supports UNIX 98 PTY";
else echo "ERROR: Linux Kernel does NOT support UNIX 98 PTY"; fi

alias_check() {
   if $1 --version 2>&1 | grep -qi $2
   then printf "OK:    %-4s is $2\n" "$1";
   else printf "ERROR: %-4s is NOT $2\n" "$1"; fi
}
echo "Aliases:"
alias_check awk GNU
alias_check yacc Bison
alias_check sh Bash

echo "Compiler check:"
if printf "int main(){}" | g++ -x c++ -
then echo "OK:    g++ works";
else echo "ERROR: g++ does NOT work"; fi
rm -f a.out

if [ "$(nproc)" = "" ]; then
   echo "ERROR: nproc is not available or it produces empty output"
else
   echo "OK: nproc reports $(nproc) logical cores are available"
fi
EOF

bash version-check.sh










----------------------------------------------------------------------------------------------------------------------
using gparted

1. create partition table msdos
2. create 512mb partition ext2 label boot
3. create 16GB partition swap lable swap
4. create rest ext4 label rootfs
5. add flag of boot only


----------------------------------------------------------------------------------------------------------------------

sudo -i

----------------------------------------------------------------------------------------------------------------------

export LFS=/mnt/lfs


----------------------------------------------------------------------------------------------------------------------

mkdir -pv $LFS
mount -v -t ext4 /dev/sda3 $LFS
/sbin/swapon -v /dev/sda2

----------------------------------------------------------------------------------------------------------------------

mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources





----------------------------------------------------------------------------------------------------------------------
in another shell from local machine

scp * ubuntu@192.168.121.101:/mnt/lfs/sources 



----------------------------------------------------------------------------------------------------------------------



cd $LFS/sources







----------------------------------------------------------------------------------------------------------------------


mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac








----------------------------------------------------------------------------------------------------------------------



mkdir -pv $LFS/tools






----------------------------------------------------------------------------------------------------------------------




groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs






----------------------------------------------------------------------------------------------------------------------



passwd lfs






----------------------------------------------------------------------------------------------------------------------


chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac







----------------------------------------------------------------------------------------------------------------------


su - lfs

----------------------------------------------------------------------------------------------------------------------


cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF


----------------------------------------------------------------------------------------------------------------------

cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF

----------------------------------------------------------------------------------------------------------------------

cat >> ~/.bashrc << "EOF"
export MAKEFLAGS=-j$(nproc)
EOF


----------------------------------------------------------------------------------------------------------------------
//////do this manually to exit lfs user and back to root


exit

cd

[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE


su - lfs


cd $LFS/sources


----------------------------------------------------------------------------------------------------------------------

tar -xf binutils-2.43.1.tar.xz
cd binutils-2.43.1
mkdir build
cd build


../configure --prefix=$LFS/tools \
             --with-sysroot=$LFS \
             --target=$LFS_TGT   \
             --disable-nls       \
             --enable-gprofng=no \
             --disable-werror    \
             --enable-new-dtags  \
             --enable-default-hash-style=gnu
             
             
             

make

make install

cd ../..

rm -rf binutils-2.43.1/






----------------------------------------------------------------------------------------------------------------------


tar -xf gcc-14.2.0.tar.xz
cd gcc-14.2.0




tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc






case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac





mkdir    build
cd       build



../configure                  \
    --target=$LFS_TGT         \
    --prefix=$LFS/tools       \
    --with-glibc-version=2.40 \
    --with-sysroot=$LFS       \
    --with-newlib             \
    --without-headers         \
    --enable-default-pie      \
    --enable-default-ssp      \
    --disable-nls             \
    --disable-shared          \
    --disable-multilib        \
    --disable-threads         \
    --disable-libatomic       \
    --disable-libgomp         \
    --disable-libquadmath     \
    --disable-libssp          \
    --disable-libvtv          \
    --disable-libstdcxx       \
    --enable-languages=c,c++
    
    
    
make

make install




cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include/limits.h
  
  
  
cd ..
rm -rf gcc-14.2.0/



----------------------------------------------------------------------------------------------------------------------



tar -xf linux-6.10.5.tar.xz

cd linux-6.10.5

make mrproper




make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $LFS/usr





cd ..

rm -rf linux-6.10.5/

----------------------------------------------------------------------------------------------------------------------

tar -xf glibc-2.40.tar.xz

cd glibc-2.40



case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 $LFS/lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 $LFS/lib64/ld-lsb-x86-64.so.3
    ;;
esac







patch -Np1 -i ../glibc-2.40-fhs-1.patch




mkdir -v build
cd       build



echo "rootsbindir=/usr/sbin" > configparms



../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=4.19               \
      --with-headers=$LFS/usr/include    \
      --disable-nscd                     \
      libc_cv_slibdir=/usr/lib
      
      
      
      
      
   
make



make DESTDIR=$LFS install




sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd


echo 'int main(){}' | $LFS_TGT-gcc -xc -
readelf -l a.out | grep ld-linux





cd ../..



rm -rf glibc-2.40/






----------------------------------------------------------------------------------------------------------------------

tar -xf gcc-14.2.0.tar.xz

cd gcc-14.2.0/

mkdir -v build
cd       build





../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --build=$(../config.guess)      \
    --prefix=/usr                   \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/14.2.0
    
    
    
    
    
    
    
make


make DESTDIR=$LFS install



rm -v $LFS/usr/lib/lib{stdc++{,exp,fs},supc++}.la


cd ../..


rm -rf gcc-14.2.0/

----------------------------------------------------------------------------------------------------------------------



tar -xf m4-1.4.19.tar.xz


cd m4-1.4.19/




./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
            




make 


make DESTDIR=$LFS install


cd ..


rm -rf m4-1.4.19/

            

----------------------------------------------------------------------------------------------------------------------


tar -xf ncurses-6.5.tar.gz


cd ncurses-6.5/



sed -i s/mawk// configure



mkdir build
pushd build
  ../configure
  make -C include
  make -C progs tic
popd






./configure --prefix=/usr                \
            --host=$LFS_TGT              \
            --build=$(./config.guess)    \
            --mandir=/usr/share/man      \
            --with-manpage-format=normal \
            --with-shared                \
            --without-normal             \
            --with-cxx-shared            \
            --without-debug              \
            --without-ada                \
            --disable-stripping
            
            
            
            
            
            
            
make






make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
ln -sv libncursesw.so $LFS/usr/lib/libncurses.so
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i $LFS/usr/include/curses.h
    
    
    
    
    
    
    
cd ..


rm -rf ncurses-6.5/
  



----------------------------------------------------------------------------------------------------------------------


tar -xf bash-5.2.32.tar.gz

cd bash-5.2.32/


./configure --prefix=/usr                      \
            --build=$(sh support/config.guess) \
            --host=$LFS_TGT                    \
            --without-bash-malloc              \
            bash_cv_strtold_broken=no
            
            
            
            
            
make


make DESTDIR=$LFS install


ln -sv bash $LFS/bin/sh



cd ..

rm -rf bash-5.2.32/



----------------------------------------------------------------------------------------------------------------------

tar -xf coreutils-9.5.tar.xz


cd coreutils-9.5/



./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --enable-install-program=hostname \
            --enable-no-install-program=kill,uptime
            
            
            
            
            
 
 
make           
            
            
make DESTDIR=$LFS install          
            
cd ..

rm -rf coreutils-9.5/        


         

----------------------------------------------------------------------------------------------------------------------


tar -xf diffutils-3.10.tar.xz

cd diffutils-3.10/



./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)
            
            
            
make

make DESTDIR=$LFS install


cd ..

rm -rf diffutils-3.10/






----------------------------------------------------------------------------------------------------------------------

tar -xf file

cd file


mkdir build
pushd build
  ../configure --disable-bzlib      \
               --disable-libseccomp \
               --disable-xzlib      \
               --disable-zlib
  make
popd


./configure --prefix=/usr --host=$LFS_TGT --build=$(./config.guess)


make FILE_COMPILE=$(pwd)/build/src/file


make DESTDIR=$LFS install


rm -v $LFS/usr/lib/libmagic.la


cd ..

rm -rf file




----------------------------------------------------------------------------------------------------------------------



tar -xf findutils

cd findutils



./configure --prefix=/usr                   \
            --localstatedir=/var/lib/locate \
            --host=$LFS_TGT                 \
            --build=$(build-aux/config.guess)





make


make DESTDIR=$LFS install




cd ..

rm -rf findutils




----------------------------------------------------------------------------------------------------------------------


tar -xf gawk

cd gawk



sed -i 's/extras//' Makefile.in


./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)



make

make DESTDIR=$LFS install


cd ..

rm -rf gawk



----------------------------------------------------------------------------------------------------------------------



tar -xf grep

cd grep

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)



make

make DESTDIR=$LFS install



cd ..

rm -rf grep



----------------------------------------------------------------------------------------------------------------------





tar -xf gzip

cd gzip



./configure --prefix=/usr --host=$LFS_TGT

make

make DESTDIR=$LFS install


cd ..

rm -rf gzip




----------------------------------------------------------------------------------------------------------------------



tar -xf make

cd make


./configure --prefix=/usr   \
            --without-guile \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)

make

make DESTDIR=$LFS install


cd ..

rm -rf make




----------------------------------------------------------------------------------------------------------------------



tar -xf patch

cd patch

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(build-aux/config.guess)
            
            

make

make DESTDIR=$LFS install

cd ..

rm -rf patch





----------------------------------------------------------------------------------------------------------------------



tar -xf sed

cd sed

./configure --prefix=/usr   \
            --host=$LFS_TGT \
            --build=$(./build-aux/config.guess)

make

make DESTDIR=$LFS install


cd ..

rm -rf sed




----------------------------------------------------------------------------------------------------------------------


tar -xf tar

cd tar

./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess)


make


make DESTDIR=$LFS install


cd ..

rm -rf tar





----------------------------------------------------------------------------------------------------------------------




tar -xf xz

cd xz


./configure --prefix=/usr                     \
            --host=$LFS_TGT                   \
            --build=$(build-aux/config.guess) \
            --disable-static                  \
            --docdir=/usr/share/doc/xz-5.6.2
            
            
            
            
make

make DESTDIR=$LFS install

rm -v $LFS/usr/lib/liblzma.la




cd ..

rm -rf xz




----------------------------------------------------------------------------------------------------------------------




tar -xf binutils

cd binutils



sed '6009s/$add_dir//' -i ltmain.sh



mkdir -v build
cd       build


../configure                   \
    --prefix=/usr              \
    --build=$(../config.guess) \
    --host=$LFS_TGT            \
    --disable-nls              \
    --enable-shared            \
    --enable-gprofng=no        \
    --disable-werror           \
    --enable-64-bit-bfd        \
    --enable-new-dtags         \
    --enable-default-hash-style=gnu
    
    
    
make   
    
make DESTDIR=$LFS install

rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}



cd ..

rm -rf binutils



----------------------------------------------------------------------------------------------------------------------




tar -xf gcc

cd gcc



tar -xf ../mpfr-4.2.1.tar.xz
mv -v mpfr-4.2.1 mpfr
tar -xf ../gmp-6.3.0.tar.xz
mv -v gmp-6.3.0 gmp
tar -xf ../mpc-1.3.1.tar.gz
mv -v mpc-1.3.1 mpc


case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac



sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in


mkdir -v build
cd       build


../configure                                       \
    --build=$(../config.guess)                     \
    --host=$LFS_TGT                                \
    --target=$LFS_TGT                              \
    LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
    --prefix=/usr                                  \
    --with-build-sysroot=$LFS                      \
    --enable-default-pie                           \
    --enable-default-ssp                           \
    --disable-nls                                  \
    --disable-multilib                             \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libsanitizer                         \
    --disable-libssp                               \
    --disable-libvtv                               \
    --enable-languages=c,c++
    
    
 
make   

make DESTDIR=$LFS install

ln -sv gcc $LFS/usr/bin/cc


    


cd ..

rm -rf gcc




----------------------------------------------------------------------------------------------------------------------

cd


exit


chown --from lfs -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown --from lfs -R root:root $LFS/lib64 ;;
esac



----------------------------------------------------------------------------------------------------------------------


mkdir -pv $LFS/{dev,proc,sys,run}


mount -v --bind /dev $LFS/dev



mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run


if [ -h $LFS/dev/shm ]; then
  install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
  mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
fi


----------------------------------------------------------------------------------------------------------------------




chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash --login





----------------------------------------------------------------------------------------------------------------------


mkdir -pv /{boot,home,mnt,opt,srv}


mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/lib/locale
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp






----------------------------------------------------------------------------------------------------------------------



ln -sv /proc/self/mounts /etc/mtab


cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF





cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF






cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF



localedef -i C -f UTF-8 C.UTF-8


exec /usr/bin/bash --login


touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp




----------------------------------------------------------------------------------------------------------------------


cd sources



----------------------------------------------------------------------------------------------------------------------

tar -xf gettext-0.22.5.tar.xz 

cd gettext

./configure --disable-shared

make

cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin



cd ..

rm -rf gettext

----------------------------------------------------------------------------------------------------------------------



tar -xf bison

cd bison


./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2




make


make install

cd ..

rm -rf bison


----------------------------------------------------------------------------------------------------------------------


tar -xf perl

cd perl


sh Configure -des                                         \
             -D prefix=/usr                               \
             -D vendorprefix=/usr                         \
             -D useshrplib                                \
             -D privlib=/usr/lib/perl5/5.40/core_perl     \
             -D archlib=/usr/lib/perl5/5.40/core_perl     \
             -D sitelib=/usr/lib/perl5/5.40/site_perl     \
             -D sitearch=/usr/lib/perl5/5.40/site_perl    \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl




make

make install




cd ..

rm -rf perl



----------------------------------------------------------------------------------------------------------------------


tar -xf Python-3.12.5.tar.xz

cd Python



./configure --prefix=/usr   \
            --enable-shared \
            --without-ensurepip
            
            
            

make

make install

cd ..

rm -rf 


----------------------------------------------------------------------------------------------------------------------


tar -xf texinfo

cd texinfo

./configure --prefix=/usr


make

make install

cd ..

rm -rf texinfo


----------------------------------------------------------------------------------------------------------------------



tar -xf util-linux

cd util-linux

mkdir -pv /var/lib/hwclock

./configure --libdir=/usr/lib     \
            --runstatedir=/run    \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-static      \
            --disable-liblastlog2 \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.40.2

make

make install


cd ..

rm -rf util-linux


----------------------------------------------------------------------------------------------------------------------


tar -xf util-linux-2.40.2.tar.xz

cd util-linux-2.40.2.tar.xz


mkdir -pv /var/lib/hwclock



./configure --libdir=/usr/lib     \
            --runstatedir=/run    \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-static      \
            --disable-liblastlog2 \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.40.2




make

make install

cd ..

rm -rf util-linux-2.40.2.tar.xz


----------------------------------------------------------------------------------------------------------------------



rm -rf /usr/share/{info,man,doc}/*




find /usr/{lib,libexec} -name \*.la -delete


----------------------------------------------------------------------------------------------------------------------



tar -xf man-pages-

cd man-pages-



rm -v man3/crypt*

make prefix=/usr install


cd ..

rm -rf man-pages-


----------------------------------------------------------------------------------------------------------------------


tar -xf iana-etc-20240806.tar.gz

cd iana-etc-20240806



cp services protocols /etc


cd ..

rm -rf iana-etc-20240806


----------------------------------------------------------------------------------------------------------------------


tar -xf tar -xf glibc-2.40.tar.xz 


cd glibc


patch -Np1 -i ../glibc-2.40-fhs-1.patch




mkdir -v build
cd       build


echo "rootsbindir=/usr/sbin" > configparms






../configure --prefix=/usr                            \
             --disable-werror                         \
             --enable-kernel=4.19                     \
             --enable-stack-protector=strong          \
             --disable-nscd                           \
             libc_cv_slibdir=/usr/lib
             
             
             
             


make



touch /etc/ld.so.conf



sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile



make install




sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd


make localedata/install-locales


localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8



localedef -i C -f UTF-8 C.UTF-8
localedef -i ja_JP -f SHIFT_JIS ja_JP.SJIS 2> /dev/null || true






cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files systemd
group: files systemd
shadow: files systemd

hosts: mymachines resolve [!UNAVAIL=return] files myhostname dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF



tar -xf ../../tzdata2024a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO








tar -xf ../../tzdata2024a.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO





ln -sfv /usr/share/zoneinfo/Africa/Algiers /etc/localtime




cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF






cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d










cd ../..

rm -rf glibc


----------------------------------------------------------------------------------------------------------------------


tar -xf zlib

cd zlib


./configure --prefix=/usr



make


make install


rm -fv /usr/lib/libz.a


cd ..

rm -rf zlib


----------------------------------------------------------------------------------------------------------------------


tar -xf bzip2-1.0.8.tar.gz

cd bzip2-1.0.8


patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch




sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile




sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile





make -f Makefile-libbz2_so
make clean




make



make PREFIX=/usr install



cp -av libbz2.so.* /usr/lib
ln -sv libbz2.so.1.0.8 /usr/lib/libbz2.so




cp -v bzip2-shared /usr/bin/bzip2
for i in /usr/bin/{bzcat,bunzip2}; do
  ln -sfv bzip2 $i
done




rm -fv /usr/lib/libbz2.a




cd ..

rm -rf bzip2-1.0.8


----------------------------------------------------------------------------------------------------------------------


tar -xf xz-5.6.2.tar.xz

cd xz




./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.6.2
            
            
            
            
            
            
            
            
            
            
make


make install






cd ..

rm -rf xz


----------------------------------------------------------------------------------------------------------------------


tar -xf lz4-1.10.0.tar.gz 

cd lz4-1.10.0/



make BUILD_STATIC=no PREFIX=/usr


make BUILD_STATIC=no PREFIX=/usr install



cd ..

rm -rf lz4-1.10.0/



----------------------------------------------------------------------------------------------------------------------


tar -xf zstd

cd zstd



make prefix=/usr


make prefix=/usr install


rm -v /usr/lib/libzstd.a



cd ..

rm -rf zstd


----------------------------------------------------------------------------------------------------------------------



tar -xf file

cd file


./configure --prefix=/usr


make


make install




cd ..

rm -rf file


----------------------------------------------------------------------------------------------------------------------


tar -xf readline

cd readline


sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install




sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf


./configure --prefix=/usr    \
            --disable-static \
            --with-curses    \
            --docdir=/usr/share/doc/readline-8.2.13
            
            
            
            
 
make SHLIB_LIBS="-lncursesw"           



make SHLIB_LIBS="-lncursesw" install



install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.2.13




cd ..

rm -rf readline


----------------------------------------------------------------------------------------------------------------------


tar -xf m4

cd m4


./configure --prefix=/usr


make


make install




cd ..

rm -rf m4


----------------------------------------------------------------------------------------------------------------------


tar -xf bc

cd bc


CC=gcc ./configure --prefix=/usr -G -O3 -r




make



make install



cd ..

rm -rf bc


----------------------------------------------------------------------------------------------------------------------


tar -xf flex

cd flex



./configure --prefix=/usr \
            --docdir=/usr/share/doc/flex-2.6.4 \
            --disable-static
            
            
            
            
            
make



make install


ln -sv flex   /usr/bin/lex
ln -sv flex.1 /usr/share/man/man1/lex.1






cd ..

rm -rf flex

----------------------------------------------------------------------------------------------------------------------


tar -xf tcl8.6.14-src.tar.gz 


cd tcl8



SRCDIR=$(pwd)
cd unix
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --disable-rpath
            
            
            
            
            
            
            
            
            
            
            
            
            
make

sed -e "s|$SRCDIR/unix|/usr/lib|" \
    -e "s|$SRCDIR|/usr/include|"  \
    -i tclConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/tdbc1.1.7|/usr/lib/tdbc1.1.7|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.7/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/tdbc1.1.7/library|/usr/lib/tcl8.6|" \
    -e "s|$SRCDIR/pkgs/tdbc1.1.7|/usr/include|"            \
    -i pkgs/tdbc1.1.7/tdbcConfig.sh

sed -e "s|$SRCDIR/unix/pkgs/itcl4.2.4|/usr/lib/itcl4.2.4|" \
    -e "s|$SRCDIR/pkgs/itcl4.2.4/generic|/usr/include|"    \
    -e "s|$SRCDIR/pkgs/itcl4.2.4|/usr/include|"            \
    -i pkgs/itcl4.2.4/itclConfig.sh

unset SRCDIR






make install


         
chmod -v u+w /usr/lib/libtcl8.6.so



make install-private-headers      
            
            
            
ln -sfv tclsh8.6 /usr/bin/tclsh



mv /usr/share/man/man3/{Thread,Tcl_Thread}.3




cd ..
tar -xf ../tcl8.6.14-html.tar.gz --strip-components=1
mkdir -v -p /usr/share/doc/tcl-8.6.14
cp -v -r  ./html/* /usr/share/doc/tcl-8.6.14





cd ..

rm -rf tcl8

----------------------------------------------------------------------------------------------------------------------

tar -xf expect5.45.4.tar.gz

cd expect5


python3 -c 'from pty import spawn; spawn(["echo", "ok"])'



patch -Np1 -i ../expect-5.45.4-gcc14-1.patch



./configure --prefix=/usr           \
            --with-tcl=/usr/lib     \
            --enable-shared         \
            --disable-rpath         \
            --mandir=/usr/share/man \
            --with-tclinclude=/usr/include
            
            
            
        
make


make install
ln -svf expect5.45.4/libexpect5.45.4.so /usr/lib




cd ..

rm -rf expect5



----------------------------------------------------------------------------------------------------------------------


tar -xf deja

cd deja


mkdir -v build
cd       build



../configure --prefix=/usr
makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
makeinfo --plaintext       -o doc/dejagnu.txt  ../doc/dejagnu.texi



make install
install -v -dm755  /usr/share/doc/dejagnu-1.6.3
install -v -m644   doc/dejagnu.{html,txt} /usr/share/doc/dejagnu-1.6.3





cd ../..

rm -rf deja


----------------------------------------------------------------------------------------------------------------------


tar -xf pkgconf-2.3.0.tar.xz

cd pkgconf


./configure --prefix=/usr              \
            --disable-static           \
            --docdir=/usr/share/doc/pkgconf-2.3.0



make

make install



ln -sv pkgconf   /usr/bin/pkg-config
ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1



cd ..

rm -rf pkgconf


----------------------------------------------------------------------------------------------------------------------


tar -xf binutils

cd binutils



mkdir -v build
cd       build




../configure --prefix=/usr       \
             --sysconfdir=/etc   \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --enable-new-dtags  \
             --with-system-zlib  \
             --enable-default-hash-style=gnu







make tooldir=/usr





make tooldir=/usr install




rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a





cd ../..

rm -rf binutils


----------------------------------------------------------------------------------------------------------------------

tar -xf gmp

cd gmp




./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.3.0





make
make html


make install
make install-html


cd ..

rm -rf gmp



----------------------------------------------------------------------------------------------------------------------

tar -xf mpfr

cd mpfr



./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.2.1




make
make html



make install
make install-html


cd ..

rm -rf mpfr



----------------------------------------------------------------------------------------------------------------------



tar -xf mpc

cd mpc


./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.3.1




make
make html


make install
make install-html




cd ..

rm -rf mpc

----------------------------------------------------------------------------------------------------------------------


tar -xf attr

cd attr


./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.5.2



make


make install


cd ..

rm -rf attr


----------------------------------------------------------------------------------------------------------------------



tar -xf acl

cd acl



./configure --prefix=/usr         \
            --disable-static      \
            --docdir=/usr/share/doc/acl-2.3.2

make

make install



cd ..

rm -rf acl


----------------------------------------------------------------------------------------------------------------------


tar -xf libcap

cd libcap


sed -i '/install -m.*STA/d' libcap/Makefile


make prefix=/usr lib=lib



make prefix=/usr lib=lib install



cd ..

rm -rf libcap


----------------------------------------------------------------------------------------------------------------------


tar -xf libxcrypt

cd libxcrypt






./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=no     \
            --disable-static             \
            --disable-failure-tokens





make


make install



make distclean
./configure --prefix=/usr                \
            --enable-hashes=strong,glibc \
            --enable-obsolete-api=glibc  \
            --disable-static             \
            --disable-failure-tokens
make
cp -av --remove-destination .libs/libcrypt.so.1* /usr/lib



cd ..

rm -rf libxcrypt


----------------------------------------------------------------------------------------------------------------------



tar -xf shadow

cd shadow





sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;




sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
    -e 's:/var/spool/mail:/var/mail:'                   \
    -e '/PATH=/{s@/sbin:@@;s@/bin:@@}'                  \
    -i etc/login.defs



sed -i 's:DICTPATH.*:DICTPATH\t/lib/cracklib/pw_dict:' etc/login.defs






touch /usr/bin/passwd
./configure --sysconfdir=/etc   \
            --disable-static    \
            --with-{b,yes}crypt \
            --without-libbsd    \
            --with-group-name-max-length=32







make





make exec_prefix=/usr install
make -C man install-man






pwconv




grpconv





mkdir -p /etc/default
useradd -D --gid 999







sed -i '/MAIL/s/yes/no/' /etc/default/useradd




passwd root








cd ..

rm -rf shadow

----------------------------------------------------------------------------------------------------------------------


tar -xf gcc

cd gcc





case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac




mkdir -v build
cd       build







../configure --prefix=/usr            \
             LD=ld                    \
             --enable-languages=c,c++ \
             --enable-default-pie     \
             --enable-default-ssp     \
             --enable-host-pie        \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-fixincludes    \
             --with-system-zlib



make



make install




ln -svr /usr/bin/cpp /usr/lib


ln -sv gcc.1 /usr/share/man/man1/cc.1



ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/14.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/



echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'


grep -E -o '/usr/lib.*/S?crt[1in].*succeeded' dummy.log


grep -B4 '^ /usr/include' dummy.log



grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'



grep "/lib.*/libc.so.6 " dummy.log


grep found dummy.log



rm -v dummy.c a.out dummy.log



mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib


cd ../..

rm -rf gcc


----------------------------------------------------------------------------------------------------------------------


tar -xf ncurses

cd ncurses




./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --with-cxx-shared       \
            --enable-pc-files       \
            --with-pkg-config-libdir=/usr/lib/pkgconfig
            
            
            
make




make DESTDIR=$PWD/dest install
install -vm755 dest/usr/lib/libncursesw.so.6.5 /usr/lib
rm -v  dest/usr/lib/libncursesw.so.6.5
sed -e 's/^#if.*XOPEN.*$/#if 1/' \
    -i dest/usr/include/curses.h
cp -av dest/* /





for lib in ncurses form panel menu ; do
    ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc    /usr/lib/pkgconfig/${lib}.pc
done





ln -sfv libncursesw.so /usr/lib/libcurses.so




cp -v -R doc -T /usr/share/doc/ncurses-6.5



make distclean
./configure --prefix=/usr    \
            --with-shared    \
            --without-normal \
            --without-debug  \
            --without-cxx-binding \
            --with-abi-version=5
make sources libs
cp -av lib/lib*.so.5* /usr/lib        







cd ..

rm -rf ncurses


----------------------------------------------------------------------------------------------------------------------


tar -xf sed

cd sed



./configure --prefix=/usr


make
make html



make install
install -d -m755           /usr/share/doc/sed-4.9
install -m644 doc/sed.html /usr/share/doc/sed-4.9






cd ..

rm -rf sed


----------------------------------------------------------------------------------------------------------------------



tar -xf psmisc

cd psmisc


./configure --prefix=/usr


make


make install




cd ..

rm -rf psmisc


----------------------------------------------------------------------------------------------------------------------



tar -xf gettext

cd gettext


./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.22.5







make





make install
chmod -v 0755 /usr/lib/preloadable_libintl.so










cd ..

rm -rf gettext




----------------------------------------------------------------------------------------------------------------------




tar -xf bison

cd bison


./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.8.2



make



make install




cd ..

rm -rf bison





----------------------------------------------------------------------------------------------------------------------



tar -xf grep

cd grep




sed -i "s/echo/#echo/" src/egrep.sh



./configure --prefix=/usr



make


make install



cd ..

rm -rf grep




----------------------------------------------------------------------------------------------------------------------




tar -xf bash

cd bash


./configure --prefix=/usr             \
            --without-bash-malloc     \
            --with-installed-readline \
            bash_cv_strtold_broken=no \
            --docdir=/usr/share/doc/bash-5.2.32








make






make install




exec /usr/bin/bash --login









cd ../..

rm -rf bash





----------------------------------------------------------------------------------------------------------------------


tar -xf libtool

cd libtool




./configure --prefix=/usr




make


make install


rm -fv /usr/lib/libltdl.a




cd ..

rm -rf libtool




----------------------------------------------------------------------------------------------------------------------




tar -xf gdbm

cd gdbm




./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat





make





make install












cd ..

rm -rf gdbm




----------------------------------------------------------------------------------------------------------------------


tar -xf gperf

cd gperf


./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1


make




make install





cd ..

rm -rf gperf




----------------------------------------------------------------------------------------------------------------------




tar -xf expat

cd expat


./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.6.2





make


make install




install -v -m644 doc/*.{html,css} /usr/share/doc/expat-2.6.2




cd ..

rm -rf expat




----------------------------------------------------------------------------------------------------------------------



tar -xf inetutils

cd inetutils





sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c



./configure --prefix=/usr        \
            --bindir=/usr/bin    \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers




make


make install



mv -v /usr/{,s}bin/ifconfig








cd ..

rm -rf inetutils




----------------------------------------------------------------------------------------------------------------------


tar -xf less

cd less

./configure --prefix=/usr --sysconfdir=/etc


make

make install



cd ..

rm -rf less


----------------------------------------------------------------------------------------------------------------------


tar -xf perl

cd perl


export BUILD_ZLIB=False
export BUILD_BZIP2=0








sh Configure -des                                          \
             -D prefix=/usr                                \
             -D vendorprefix=/usr                          \
             -D privlib=/usr/lib/perl5/5.40/core_perl      \
             -D archlib=/usr/lib/perl5/5.40/core_perl      \
             -D sitelib=/usr/lib/perl5/5.40/site_perl      \
             -D sitearch=/usr/lib/perl5/5.40/site_perl     \
             -D vendorlib=/usr/lib/perl5/5.40/vendor_perl  \
             -D vendorarch=/usr/lib/perl5/5.40/vendor_perl \
             -D man1dir=/usr/share/man/man1                \
             -D man3dir=/usr/share/man/man3                \
             -D pager="/usr/bin/less -isR"                 \
             -D useshrplib                                 \
             -D usethreads






make





make install
unset BUILD_ZLIB BUILD_BZIP2







cd ..

rm -rf perl



----------------------------------------------------------------------------------------------------------------------


tar -xf XML

cd XML


perl Makefile.PL




make



make install




cd ..

rm -rf XML



----------------------------------------------------------------------------------------------------------------------



tar -xf intltool

cd intltool



sed -i 's:\\\${:\\\$\\{:' intltool-update.in
	
	
	
	
	
	



./configure --prefix=/usr





make




make check



make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO


cd ..

rm -rf intltool


----------------------------------------------------------------------------------------------------------------------




tar -xf autoconf

cd autoconf


./configure --prefix=/usr



make




make install




cd ..

rm -rf autoconf


----------------------------------------------------------------------------------------------------------------------


tar -xf automake

cd automake



make




make install









cd ..

rm -rf automake



----------------------------------------------------------------------------------------------------------------------




tar -xf openSSL

cd OpenSSL


./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
         

make






sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install





mv -v /usr/share/doc/openssl /usr/share/doc/openssl-3.3.1






cp -vfr doc/* /usr/share/doc/openssl-3.3.1




cd ..

rm -rf OpenSSL





----------------------------------------------------------------------------------------------------------------------



tar -xf kmod

cd kmod


./configure --prefix=/usr     \
            --sysconfdir=/etc \
            --with-openssl    \
            --with-xz         \
            --with-zstd       \
            --with-zlib       \
            --disable-manpages




make






make install

for target in depmod insmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /usr/sbin/$target
  rm -fv /usr/bin/$target
done






cd ..

rm -rf kmod


----------------------------------------------------------------------------------------------------------------------



tar -xf elfutils

cd elfutils



./configure --prefix=/usr                \
            --disable-debuginfod         \
            --enable-libdebuginfod=dummy



make



make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
rm /usr/lib/libelf.a


cd ..

rm -rf elfutils



----------------------------------------------------------------------------------------------------------------------



tar -xf libffi

cd libffi



./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native




make





make install




cd ..

rm -rf libffi


----------------------------------------------------------------------------------------------------------------------



tar -xf Python

cd Python


./configure --prefix=/usr        \
            --enable-shared      \
            --with-system-expat  \
            --enable-optimizations





make



make install





cat > /etc/pip.conf << EOF
[global]
root-user-action = ignore
disable-pip-version-check = true
EOF





install -v -dm755 /usr/share/doc/python-3.12.5/html

tar --no-same-owner \
    -xvf ../python-3.12.5-docs-html.tar.bz2
cp -R --no-preserve=mode python-3.12.5-docs-html/* \
    /usr/share/doc/python-3.12.5/html





cd ..

rm -rf Python



----------------------------------------------------------------------------------------------------------------------



tar -xf flit

cd flit


pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD


pip3 install --no-index --no-user --find-links dist flit_core



cd ..

rm -rf flit




----------------------------------------------------------------------------------------------------------------------



tar -xf wheel

cd wheel

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

pip3 install --no-index --find-links=dist wheel

cd ..

rm -rf wheel



----------------------------------------------------------------------------------------------------------------------



tar -xf setuptools

cd setuptools



pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD



pip3 install --no-index --find-links dist setuptools




cd ..

rm -rf setuptools




----------------------------------------------------------------------------------------------------------------------



tar -xf ninja

cd ninja





sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc






python3 configure.py --bootstrap










install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja










cd ..

rm -rf ninja




----------------------------------------------------------------------------------------------------------------------



tar -xf meson

cd meson



pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD




pip3 install --no-index --find-links dist meson
install -vDm644 data/shell-completions/bash/meson /usr/share/bash-completion/completions/meson
install -vDm644 data/shell-completions/zsh/_meson /usr/share/zsh/site-functions/_meson







cd ..

rm -rf meson




----------------------------------------------------------------------------------------------------------------------




tar -xf coreutils

cd coreutils


patch -Np1 -i ../coreutils-9.5-i18n-2.patch





autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime





make



make install





mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8






cd ..

rm -rf coreutils





----------------------------------------------------------------------------------------------------------------------




tar -xf check

cd check


./configure --prefix=/usr --disable-static



make

make docdir=/usr/share/doc/check-0.15.2 install




cd ..

rm -rf check





----------------------------------------------------------------------------------------------------------------------



tar -xf diffutils

cd diffutils



./configure --prefix=/usr





make




make install


cd ..

rm -rf diffutils




----------------------------------------------------------------------------------------------------------------------





tar -xf gawk

cd gawk


sed -i 's/extras//' Makefile.in





./configure --prefix=/usr




make




rm -f /usr/bin/gawk-5.3.0
make install




ln -sv gawk.1 /usr/share/man/man1/awk.1




mkdir -pv                                   /usr/share/doc/gawk-5.3.0
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.3.0




cd ..

rm -rf gawk




----------------------------------------------------------------------------------------------------------------------



tar -xf findutils

cd findutils



./configure --prefix=/usr --localstatedir=/var/lib/locate





make






make install







cd ..

rm -rf findutils



----------------------------------------------------------------------------------------------------------------------




tar -xf groff

cd groff


PAGE=A4 ./configure --prefix=/usr



make



make install





cd ..

rm -rf groff




----------------------------------------------------------------------------------------------------------------------


tar -xf grub

cd grub


unset {C,CPP,CXX,LD}FLAGS


echo depends bli part_gpt > grub-core/extra_deps.lst



./configure --prefix=/usr          \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror
            






make




make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions






cd ..

rm -rf grub




----------------------------------------------------------------------------------------------------------------------



tar -xf gzip

cd gzip


./configure --prefix=/usr



make



make install




cd ..

rm -rf gzip





----------------------------------------------------------------------------------------------------------------------



tar -xf iproute

cd iproute




sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8



make NETNS_RUN_DIR=/run/netns




make SBINDIR=/usr/sbin install




mkdir -pv             /usr/share/doc/iproute2-6.10.0
cp -v COPYING README* /usr/share/doc/iproute2-6.10.0






cd ..

rm -rf iproute




----------------------------------------------------------------------------------------------------------------------


tar -xf kbd

cd kbd



patch -Np1 -i ../kbd-2.6.4-backspace-1.patch




sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in




./configure --prefix=/usr --disable-vlock







make



make install



cp -R -v docs/doc -T /usr/share/doc/kbd-2.6.4





cd ..

rm -rf kbd



----------------------------------------------------------------------------------------------------------------------



tar -xf libpipeline

cd libpipeline


./configure --prefix=/usr




make




make install






cd ..

rm -rf libpipeline




----------------------------------------------------------------------------------------------------------------------




tar -xf make

cd make


./configure --prefix=/usr




make




make install






cd ..

rm -rf make




----------------------------------------------------------------------------------------------------------------------



tar -xf patch

cd patch


./configure --prefix=/usr


make



make install




cd ..

rm -rf patch




----------------------------------------------------------------------------------------------------------------------



tar -xf tar

cd tar





FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr




make




make install
make -C doc install-html docdir=/usr/share/doc/tar-1.35



cd ..

rm -rf tar






----------------------------------------------------------------------------------------------------------------------



tar -xf texinfo

cd texinfo


./configure --prefix=/usr




make



make install



make TEXMF=/usr/share/texmf install-tex


cd ..

rm -rf texinfo




----------------------------------------------------------------------------------------------------------------------





tar -xf vim

cd vim

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

./configure --prefix=/usr

make

make install



ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done



ln -sv ../vim/vim91/doc /usr/share/doc/vim-9.1.0660





cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF







cd ..

rm -rf vim




----------------------------------------------------------------------------------------------------------------------



tar -xf MarkupSafe

cd MarkupSafe




pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD




pip3 install --no-index --no-user --find-links dist Markupsafe


cd ..

rm -rf MarkupSafe



----------------------------------------------------------------------------------------------------------------------




tar -xf Jinja2

cd Jinja2

pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD


pip3 install --no-index --no-user --find-links dist Jinja2


cd ..

rm -rf Jinja2




----------------------------------------------------------------------------------------------------------------------


tar -xf Systemd-256.4

cd Systemd-256.4




sed -i -e 's/GROUP="render"/GROUP="video"/' \
       -e 's/GROUP="sgx", //' rules.d/50-udev-default.rules.in
       
       



mkdir -p build
cd       build

meson setup ..                \
      --prefix=/usr           \
      --buildtype=release     \
      -D default-dnssec=no    \
      -D firstboot=false      \
      -D install-tests=false  \
      -D ldconfig=false       \
      -D sysusers=false       \
      -D rpmmacrosdir=no      \
      -D homed=disabled       \
      -D userdb=false         \
      -D man=disabled         \
      -D mode=release         \
      -D pamconfdir=no        \
      -D dev-kvm-mode=0660    \
      -D nobody-group=nogroup \
      -D sysupdate=disabled   \
      -D ukify=disabled       \
      -D docdir=/usr/share/doc/systemd-256.4      











ninja





ninja install




tar -xf ../../systemd-man-pages-256.4.tar.xz \
    --no-same-owner --strip-components=1   \
    -C /usr/share/man








systemd-machine-id-setup




systemctl preset-all





cd ..

rm -rf Systemd-256.4




----------------------------------------------------------------------------------------------------------------------


tar -xf dbus

cd dbus


./configure --prefix=/usr                        \
            --sysconfdir=/etc                    \
            --localstatedir=/var                 \
            --runstatedir=/run                   \
            --enable-user-session                \
            --disable-static                     \
            --disable-doxygen-docs               \
            --disable-xml-docs                   \
            --docdir=/usr/share/doc/dbus-1.14.10 \
            --with-system-socket=/run/dbus/system_bus_socket




make


make install

ln -sfv /etc/machine-id /var/lib/dbus






cd ..

rm -rf dbus






----------------------------------------------------------------------------------------------------------------------



tar -xf man-db

cd man-db


./configure --prefix=/usr                         \
            --docdir=/usr/share/doc/man-db-2.12.1 \
            --sysconfdir=/etc                     \
            --disable-setuid                      \
            --enable-cache-owner=bin              \
            --with-browser=/usr/bin/lynx          \
            --with-vgrind=/usr/bin/vgrind         \
            --with-grap=/usr/bin/grap







make




make install







cd ..

rm -rf man-db




----------------------------------------------------------------------------------------------------------------------



tar -xf procps

cd procps





./configure --prefix=/usr                           \
            --docdir=/usr/share/doc/procps-ng-4.0.4 \
            --disable-static                        \
            --disable-kill                          \
            --with-systemd





make src_w_LDADD='$(LDADD) -lsystemd'




make install










cd ..

rm -rf procps






----------------------------------------------------------------------------------------------------------------------



tar -xf util-linux

cd util-linux


./configure --bindir=/usr/bin     \
            --libdir=/usr/lib     \
            --runstatedir=/run    \
            --sbindir=/usr/sbin   \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-liblastlog2 \
            --disable-static      \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.40.2




make


make install



rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a



gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info



makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info


sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf




cd ..

rm -rf util-linux






----------------------------------------------------------------------------------------------------------------------



tar -xf e2fsprogs

cd e2fsprogs




mkdir -v build
cd       build




../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck



make



make install



rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a



gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info





makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info




sed 's/metadata_csum_seed,//' -i /etc/mke2fs.conf







cd ..

rm -rf e2fsprogs




----------------------------------------------------------------------------------------------------------------------



save_usrlib="$(cd /usr/lib; ls ld-linux*[^g])
             libc.so.6
             libthread_db.so.1
             libquadmath.so.0.0.0
             libstdc++.so.6.0.33
             libitm.so.1.0.0
             libatomic.so.1.2.0"

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug --compress-debug-sections=zlib $LIB $LIB.dbg
    cp $LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    objcopy --add-gnu-debuglink=$LIB.dbg /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

online_usrbin="bash find strip"
online_usrlib="libbfd-2.43.1.so
               libsframe.so.1.0.0
               libhistory.so.8.2
               libncursesw.so.6.5
               libm.so.6
               libreadline.so.8.2
               libz.so.1.3.1
               libzstd.so.1.5.6
               $(cd /usr/lib; find libnss*.so* -type f)"

for BIN in $online_usrbin; do
    cp /usr/bin/$BIN /tmp/$BIN
    strip --strip-unneeded /tmp/$BIN
    install -vm755 /tmp/$BIN /usr/bin
    rm /tmp/$BIN
done

for LIB in $online_usrlib; do
    cp /usr/lib/$LIB /tmp/$LIB
    strip --strip-unneeded /tmp/$LIB
    install -vm755 /tmp/$LIB /usr/lib
    rm /tmp/$LIB
done

for i in $(find /usr/lib -type f -name \*.so* ! -name \*dbg) \
         $(find /usr/lib -type f -name \*.a)                 \
         $(find /usr/{bin,sbin,libexec} -type f); do
    case "$online_usrbin $online_usrlib $save_usrlib" in
        *$(basename $i)* )
            ;;
        * ) strip --strip-unneeded $i
            ;;
    esac
done

unset BIN LIB save_usrlib online_usrbin online_usrlib






----------------------------------------------------------------------------------------------------------------------


rm -rf /tmp/{*,.*}



find /usr/lib /usr/libexec -name \*.la -delete


find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf


----------------------------------------------------------------------------------------------------------------------



cat > /etc/systemd/network/10-ether0.link << "EOF"
[Match]
# Change the MAC address as appropriate for your network device
MACAddress=08:00:27:c2:da:9a

[Link]
Name=enp0s3
EOF





----------------------------------------------------------------------------------------------------------------------


cat > /etc/systemd/network/10-eth-dhcp.network << "EOF"
[Match]
Name=enp0s3

[Network]
DHCP=ipv4

[DHCPv4]
UseDomains=true
EOF



----------------------------------------------------------------------------------------------------------------------



echo "<lfs>" > /etc/hostname





----------------------------------------------------------------------------------------------------------------------


udevadm info -a -p /sys/class/video4linux/video0






cat > /etc/udev/rules.d/83-duplicate_devs.rules << "EOF"

# Persistent symlinks for webcam and tuner
KERNEL=="video*", ATTRS{idProduct}=="1910", ATTRS{idVendor}=="0d81", SYMLINK+="webcam"
KERNEL=="video*", ATTRS{device}=="0x036f",  ATTRS{vendor}=="0x109e", SYMLINK+="tvtuner"

EOF

----------------------------------------------------------------------------------------------------------------------


check managing devices





----------------------------------------------------------------------------------------------------------------------

timedatectl set-timezone Africa/Algiers

----------------------------------------------------------------------------------------------------------------------


LC_ALL=en_US.UTF-8 locale language
LC_ALL=fr_FR.UTF-8 locale charmap
LC_ALL=fr_FR.UTF-8 locale int_curr_symbol
LC_ALL=fr_FR.UTF-8 locale int_prefix


----------------------------------------------------------------------------------------------------------------------


cat > /etc/profile << "EOF"
# Begin /etc/profile

for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  source /etc/locale.conf

  for i in $(locale); do
    key=${i%=*}
    if [[ -v $key ]]; then
      export $key
    fi
  done
fi

# End /etc/profile
EOF



----------------------------------------------------------------------------------------------------------------------


cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8-bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF



----------------------------------------------------------------------------------------------------------------------


mkdir -pv /etc/systemd/coredump.conf.d

cat > /etc/systemd/coredump.conf.d/maxuse.conf << EOF
[Coredump]
MaxUse=5G
EOF


----------------------------------------------------------------------------------------------------------------------


cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/sda3      /            ext4     defaults            1     1
/dev/sda2      swap         swap     pri=1               0     0

# End /etc/fstab
EOF


----------------------------------------------------------------------------------------------------------------------


cd

cd /sources


tar -xf linux-6.10.5.tar.xz

cd linux


make mrproper


make defconfig


make menuconfig









/////kernal check stat of system if nvme or other








make



make modules_install


cp -iv arch/x86/boot/bzImage /boot/vmlinuz-6.10.5-lfs-12.2-systemd


cp -iv System.map /boot/System.map-6.10.5


cp -iv .config /boot/config-6.10.5


cp -r Documentation -T /usr/share/doc/linux-6.10.5




install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF





cd ..


rm -rf linux

----------------------------------------------------------------------------------------------------------------------


grub-install /dev/sda




grub-mkconfig -o /boot/grub/grub.cfg



mount /dev/sda1 /mnt




cp -R /boot /mnt


ls /mnt/boot/


unmount /dev/sda1


cd 



exit


exit






----------------------------------------------------------------------------------------------------------------------


reboot



----------------------------------------------------------------------------------------------------------------------






----------------------------------------------------------------------------------------------------------------------

try to make a disk image

lsblk

sudo dd if=/path/to/output_disk.img of=/dev/sdX bs=4M status=progress



----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------

cat > /usr/sbin/remove-la-files.sh << "EOF"
#!/bin/bash

# /usr/sbin/remove-la-files.sh
# Written for Beyond Linux From Scratch
# by Bruce Dubbs <bdubbs@linuxfromscratch.org>

# Make sure we are running with root privs
if test "${EUID}" -ne 0; then
    echo "Error: $(basename ${0}) must be run as the root user! Exiting..."
    exit 1
fi

# Make sure PKG_CONFIG_PATH is set if discarded by sudo
source /etc/profile

OLD_LA_DIR=/var/local/la-files

mkdir -p $OLD_LA_DIR

# Only search directories in /opt, but not symlinks to directories
OPTDIRS=$(find /opt -mindepth 1 -maxdepth 1 -type d)

# Move any found .la files to a directory out of the way
find /usr/lib $OPTDIRS -name "*.la" ! -path "/usr/lib/ImageMagick*" \
  -exec mv -fv {} $OLD_LA_DIR \;
###############

# Fix any .pc files that may have .la references

STD_PC_PATH='/usr/lib/pkgconfig
             /usr/share/pkgconfig
             /usr/local/lib/pkgconfig
             /usr/local/share/pkgconfig'

# For each directory that can have .pc files
for d in $(echo $PKG_CONFIG_PATH | tr : ' ') $STD_PC_PATH; do

  # For each pc file
  for pc in $d/*.pc ; do
    if [ $pc == "$d/*.pc" ]; then continue; fi

    # Check each word in a line with a .la reference
    for word in $(grep '\.la' $pc); do
      if $(echo $word | grep -q '.la$' ); then
        mkdir -p $d/la-backup
        cp -fv  $pc $d/la-backup

        basename=$(basename $word )
        libref=$(echo $basename|sed -e 's/^lib/-l/' -e 's/\.la$//')

        # Fix the .pc file
        sed -i "s:$word:$libref:" $pc
      fi
    done
  done
done

EOF

chmod +x /usr/sbin/remove-la-files.sh



----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------






----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------






----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------




----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------






----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------






----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------










----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------










----------------------------------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------------------------------









----------------------------------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------------------------------









----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------






----------------------------------------------------------------------------------------------------------------------






----------------------------------------------------------------------------------------------------------------------






----------------------------------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------------------------------






----------------------------------------------------------------------------------------------------------------------










----------------------------------------------------------------------------------------------------------------------






----------------------------------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------------------------------






----------------------------------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------










----------------------------------------------------------------------------------------------------------------------










----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------










----------------------------------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------------------------------









----------------------------------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------------------------------









----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------





----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------









----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------










----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------










----------------------------------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------------------------------









----------------------------------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------------------------------









----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------










----------------------------------------------------------------------------------------------------------------------










----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------










----------------------------------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------------------------------









----------------------------------------------------------------------------------------------------------------------







----------------------------------------------------------------------------------------------------------------------









----------------------------------------------------------------------------------------------------------------------








----------------------------------------------------------------------------------------------------------------------







