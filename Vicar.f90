!*==MAKEXYZ.f90  processed by SPAG 6.11Dc at 13:14 on 17 Sep 2001
      SUBROUTINE makexyz(n,blen,alph,bet,iz1,iz2,iz3,x,y,z)
      IMPLICIT NONE
!     Arguments
      INTEGER n
      INTEGER iz1(*), iz2(*), iz3(*)
      DOUBLE PRECISION x(*), y(*), z(*), blen(*), alph(*), bet(*)
!     Constants
      REAL*8 radian, pi, sqrtpi, twosix, logten
      PARAMETER (radian=57.29577951308232088D0)
      PARAMETER (pi=3.141592653589793238D0)
      PARAMETER (sqrtpi=1.772453850905516027D0)
      PARAMETER (twosix=1.122462048309372981D0)
      PARAMETER (logten=2.302585092994045684D0)
!     Local
!  replace radian with rad=(1/radian)
      INTEGER i, k, i1, i2, i3
      REAL*8 bond, angle1, angle2, sign, rad
!
! cosmetic change to demo cvs
      IF (N.LT.1) RETURN
      rad = 1.0/radian
!     First atom is placed at the origin
      x(1) = 0.0D0
      y(1) = 0.0D0
      z(1) = 0.0D0
!     Second atom is placed along the z-axis
      IF (N.LT.2) RETURN
      x(2) = 0.0D0
      y(2) = 0.0D0
      z(2) = blen(2)
!     Third atom is placed in the x,z-plane
      IF (N.LT.3) RETURN
      x(3) = blen(3)*SIN(alph(3)*rad)
      y(3) = 0.0D0
      IF (iz1(3).EQ.1) THEN
        z(3) = blen(3)*COS(alph(3)*rad)
      ELSE
        z(3) = z(2) - blen(3)*COS(alph(3)*rad)
      ENDIF
!     As long as atoms remain linear with the first
!     two atoms, keep placing them along the z-axis
      i = 3
      IF (n.GT.3) THEN
        DO WHILE (nint(x(i)*10000).EQ.0)
          i = i + 1
          i1 = iz1(i)
          i2 = iz2(i)
          IF (z(i1).GT.z(i2)) THEN
            sign = 1.0D0
          ELSE
            sign = -1.0D0
          ENDIF
          x(i) = blen(i)*sin(alph(i)*rad)
          y(i) = 0.0D0
          z(i) = z(i1) - sign*blen(i)*cos(alph(i)*rad)
        ENDDO
      ENDIF
!     Loop over each atom in turn, finding its coordinates
      k = i + 1
      IF (k.LE.n) THEN
        DO i = k, n
          i1 = iz1(i)
          i2 = iz2(i)
          i3 = iz3(i)
          bond = blen(i)
          angle1 = alph(i)
          angle2 = bet(i)
          CALL xyzatm(x,y,z,i,i1,bond,i2,angle1,i3,angle2)
        ENDDO
      ENDIF
      RETURN
      END SUBROUTINE MAKEXYZ
!*==XYZATM.f90  processed by SPAG 6.11Dc at 13:14 on 17 Sep 2001
!
!     "xyzatm" computes the Cartesian coordinates of a single
!     atom from its defining internal coordinate values
!
      SUBROUTINE xyzatm(x,y,z,i,i1,bond,i2,angle1,i3,angle2)
!
      IMPLICIT NONE
!
!     Arguments
      REAL*8 x(*), y(*), z(*)
      REAL*8 bond, angle1, angle2
      INTEGER i, i1, i2, i3
!     Constants
      REAL*8 radian, pi, sqrtpi, twosix, logten
      PARAMETER (radian=57.29577951308232088D0)
      PARAMETER (pi=3.141592653589793238D0)
      PARAMETER (sqrtpi=1.772453850905516027D0)
      PARAMETER (twosix=1.122462048309372981D0)
      PARAMETER (logten=2.302585092994045684D0)
      REAL*8 small
      PARAMETER (small=1.D-8)
!     Local
      REAL*8 ang_1, ang_2
      REAL*8 sin_1, cos_1, sin_2, cos_2
      REAL*8 cosine, one_over_sine, norm, eps, sinarg
      REAL*8 u1(3), u2(3), u3(3), u4(3), rad
!
!     convert the angle values from degrees to radians;
!     then find their sine and cosine values
!
      eps = 0.00000001D0
      rad = 1.0/radian
      ang_1 = angle1*rad
      ang_2 = angle2*rad
      sin_1 = sin(ang_1)
      cos_1 = cos(ang_1)
      sin_2 = sin(ang_2)
      cos_2 = cos(ang_2)
      u1(1) = x(i2) - x(i3)
      u1(2) = y(i2) - y(i3)
      u1(3) = z(i2) - z(i3)
      norm = 1.0/sqrt(u1(1)*u1(1)+u1(2)*u1(2)+u1(3)*u1(3))
      u1(1) = u1(1)*norm
      u1(2) = u1(2)*norm
      u1(3) = u1(3)*norm
      u2(1) = x(i1) - x(i2)
      u2(2) = y(i1) - y(i2)
      u2(3) = z(i1) - z(i2)
      norm = 1.0/sqrt(u2(1)*u2(1)+u2(2)*u2(2)+u2(3)*u2(3))
      u2(1) = u2(1)*norm
      u2(2) = u2(2)*norm
      u2(3) = u2(3)*norm
      u3(1) = u1(2)*u2(3) - u1(3)*u2(2)
      u3(2) = u1(3)*u2(1) - u1(1)*u2(3)
      u3(3) = u1(1)*u2(2) - u1(2)*u2(1)
      cosine = u1(1)*u2(1) + u1(2)*u2(2) + u1(3)*u2(3)
      IF (abs(cosine).LT.1.0D0) THEN
        one_over_sine = 1.0/sqrt(1.0D0-cosine**2)
      ELSE
!         write (*,10)  i
!   10    format (' XYZATM - Undefined Dihed Angle at Atom',i6)
        sinarg = dmax1(small,cosine**2-1.0D0)
!	 write (*,*) ' cosine is ',cosine,sinarg
        one_over_sine = 1.0/sqrt(sinarg)
!	 write (*,*) ' cosine is ',cosine,sinarg
!         sine = 1.0/sqrt(cosine**2 - 1.0d0)
      ENDIF
      u3(1) = u3(1)*one_over_sine
      u3(2) = u3(2)*one_over_sine
      u3(3) = u3(3)*one_over_sine
      u4(1) = u3(2)*u2(3) - u3(3)*u2(2)
      u4(2) = u3(3)*u2(1) - u3(1)*u2(3)
      u4(3) = u3(1)*u2(2) - u3(2)*u2(1)
      x(i) = x(i1) + bond*(-u2(1)*cos_1+u4(1)*sin_1*cos_2+u3(1)         &
     &       *sin_1*sin_2)
      y(i) = y(i1) + bond*(-u2(2)*cos_1+u4(2)*sin_1*cos_2+u3(2)         &
     &       *sin_1*sin_2)
      z(i) = z(i1) + bond*(-u2(3)*cos_1+u4(3)*sin_1*cos_2+u3(3)         &
     &       *sin_1*sin_2)
      RETURN
!
      END SUBROUTINE XYZATM