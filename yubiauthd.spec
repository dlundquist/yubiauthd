Name: yubiauthd
Version: unknown
Release: unknown
Summary: Yubikey two factor authentication system

Group: System/utilities
License: Apache License, Version 2.0
Vendor: Blue Box Group, Inc.
Source0: %{name}-%{version}.tar.bz2
BuildArch: noarch
BuildRoot: %{_tmppath}/%{name}-%{version}
Requires: perl

%description
YubiAuthd is a authenticates YubiKey one time passwords and synchronizes
counter updates between multiple machines to prevent replay attacks.

%prep
%setup -q


%build


%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT


%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

install -b -D -m 0644 etc/yubiauth.conf ${RPM_BUILD_ROOT}/%{_sysconfdir}/yubiauth.conf
install -b -D -m 0600 etc/yubiauthd.conf ${RPM_BUILD_ROOT}/%{_sysconfdir}/yubiauthd.conf
install -b -D -m 0755 src/yubiauth ${RPM_BUILD_ROOT}/usr/bin/yubiauth
install -b -D -m 0755 src/yubiauthd ${RPM_BUILD_ROOT}/usr/sbin/yubiauthd
for FILE in AuthenticationChallenge.pm \
        AuthenticationSession.pm \
        AuthenticationSocket.pm \
        FileIdentityStore.pm \
        IdentityBuilder.pm \
        Identity.pm \
        IdentityStore.pm \
        Log.pm \
        SQLiteIdentityStore.pm \
        SynchronizationMessage.pm \
        SynchronizationPeer.pm \
        SynchronizationSocket.pm
do
    install -b -D -m 0644 lib/YubiAuthd/${FILE} ${RPM_BUILD_ROOT}/%{perl_vendorlib}/YubiAuthd/${FILE}
done

%files
%defattr(755,root,root)
/usr/bin/yubiauth
/usr/sbin/yubiauthd
%defattr(644,root,root)
%{perl_vendorlib}/YubiAuthd/AuthenticationChallenge.pm
%{perl_vendorlib}/YubiAuthd/AuthenticationSession.pm
%{perl_vendorlib}/YubiAuthd/AuthenticationSocket.pm
%{perl_vendorlib}/YubiAuthd/FileIdentityStore.pm
%{perl_vendorlib}/YubiAuthd/IdentityBuilder.pm
%{perl_vendorlib}/YubiAuthd/Identity.pm
%{perl_vendorlib}/YubiAuthd/IdentityStore.pm
%{perl_vendorlib}/YubiAuthd/Log.pm
%{perl_vendorlib}/YubiAuthd/SQLiteIdentityStore.pm
%{perl_vendorlib}/YubiAuthd/SynchronizationMessage.pm
%{perl_vendorlib}/YubiAuthd/SynchronizationPeer.pm
%{perl_vendorlib}/YubiAuthd/SynchronizationSocket.pm
%config %{_sysconfdir}/yubiauth.conf
%defattr(600,root,root)
%config %{_sysconfdir}/yubiauthd.conf


%changelog
