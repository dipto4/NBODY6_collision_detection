      SUBROUTINE CSTAB2(ITERM)
*
*
*       Degenerate triple chain stability test.
*       ---------------------------------------
*
      INCLUDE 'commonc.h'
      INCLUDE 'common2.h'
      INCLUDE 'mpi_base.h'
      COMMON/CHREG/  TIMEC,TMAX,RMAXC,CM(10),NAMEC(6),NSTEP1,KZ27,KZ30
      REAL*8  M,MB,MB1,R2(NMX,NMX),XCM(3),VCM(3),XX(3,3),VV(3,3),
     &        XCM3(3),VCM3(3)
      INTEGER  IJ(NMX)
*
*
*       Sort particle separations (I1 & I2 form closest pair).
      CALL R2SORT(IJ,R2)
      I1 = IJ(1)
      I2 = IJ(2)
      I3 = IJ(3)
      I4 = IJ(4)
      MB = M(I1) + M(I2)
      MB1 = MB + M(I3)
      MB2 = MB1 + M(I4)
*
*       Form output diagnostics with smallest binary as one body.
      VREL2 = 0.0D0
      VREL21 = 0.0D0
      RDOT = 0.0D0
      RDOT3 = 0.0D0
      RB0 = 0.0
      RI2 = 0.0D0
      R4 = 0.0D0
      V4 = 0.0
      RDOT4 = 0.0D0
      DO 10 K = 1,3
          J1 = 3*(I1-1) + K
          J2 = 3*(I2-1) + K
          J3 = 3*(I3-1) + K
          J4 = 3*(I4-1) + K
          RB0 = RB0 + (X(J1) - X(J2))**2
          VREL2 = VREL2 + (V(J1) - V(J2))**2
          RDOT = RDOT + (X(J1) - X(J2))*(V(J1) - V(J2))
          XCM(K) = (M(I1)*X(J1) + M(I2)*X(J2))/MB
          VCM(K) = (M(I1)*V(J1) + M(I2)*V(J2))/MB
          RI2 = RI2 + (X(J3) - XCM(K))**2
          VREL21 = VREL21 + (V(J3) - VCM(K))**2
          RDOT3 = RDOT3 + (X(J3) - XCM(K))*(V(J3) - VCM(K))
          XCM3(K) = (M(I3)*X(J3) + MB*XCM(K))/MB1
          VCM3(K) = (M(I3)*V(J3) + MB*VCM(K))/MB1
          R4 = R4 + (X(J4) - XCM3(K))**2
          V4 = V4 + (V(J4) - VCM3(K))**2
          RDOT4 = RDOT4 + (X(J4) - XCM3(K))*(V(J4) - VCM3(K))
          XX(K,1) = XCM(K)
          XX(K,2) = XCM3(K)
          XX(K,3) = X(J4) - XCM3(K)
          VV(K,1) = VCM(K)
          VV(K,2) = VCM3(K)
          VV(K,3) = V(J4) - VCM3(K)
   10 CONTINUE
*
*       Evaluate orbital elements for inner and outer motion.
      RB = SQRT(RI2)
      R4 = SQRT(R4)
      SEMI = 2.0D0/RB - VREL21/MB1
      SEMI = 1.0/SEMI
      ECC = SQRT((1.0D0 - RB/SEMI)**2 + RDOT3**2/(SEMI*MB1))
      SEMI1 = 2.0/R4 - V4/MB2
      SEMI1 = 1.0/SEMI1
      ECC1 = SQRT((1.0D0 - R4/SEMI1)**2 + RDOT4**2/(SEMI1*MB2))
*
*       Skip if innermost triple is not stable (including ECC > 1).
      RB0 = SQRT(RB0)
      SEMI0 = 2.0/RB0 - VREL2/MB
      SEMI0 = 1.0/SEMI0
      IF (SEMI0.LT.0.0.OR.ECC.GT.1.0) GO TO 40
      ECC0 = SQRT((1.0 - RB0/SEMI0)**2 + RDOT**2/(SEMI0*MB))
*       Obtain the inclination (in radians).
      CALL INCLIN(XX,VV,XCM3,VCM3,ALPHA)
*       Evaluate the Valtonen stability criterion.
      QST = QSTAB(ECC0,ECC,ALPHA,M(I1),M(I2),M(I3))
      PCRIT0 = QST*SEMI0
      IF (SEMI*(1.0 - ECC).LT.QST*SEMI0) GO TO 40
*
*       Form hierarchical stability ratio (Eggleton & Kiseleva 1995).
*     QL = MB1/M(I4)
*     Q1 = MAX(MB/MB1,MB1/MB)
*     Q3 = QL**0.33333
*     Q13 = Q1**0.33333
*     AR = 1.0 + 3.7/Q3 - 2.2/(1.0 + Q3) + 1.4/Q13*(Q3 - 1.0)/(Q3 + 1.0)
*
*     EK = AR*SEMI*(1.0D0 + ECC)
C      PMIN = SEMI1*(1.0D0 - ECC1)
*
*       Obtain the inclination (in radians).
C      CALL INCLIN(XX,VV,XCM3,VCM3,ALPHA)
*
*       Replace the EK criterion by the MA 1999 stability formula.
C      PC99 = stability(MB,M(I3),M(I4),ECC,ECC1,ALPHA)*SEMI
*
*       Evaluate the general stability function.
C      IF (ECC1.LT.1.0) THEN
C          NST = NSTAB(SEMI,SEMI1,ECC,ECC1,ALPHA,MB,M(I3),M(I4))
C          IF (NST.EQ.0) THEN
C              PCRIT = 0.99*PMIN
C          ELSE
C              PCRIT = 1.01*PMIN
C          END IF
C      ELSE
C          PCRIT = 1.01*PMIN
C      END IF
*
*       Check hierarchical stability condition (SEMI1 > 0 => ECC1 < 1).
C      ITERM = 0
      PMIN0 = SEMI*(1.0 - ECC)
      PMIN = SEMI1*(1.0D0 - ECC1)
      IF (PMIN.GT.QST*SEMI.AND.SEMI.GT.0.0.AND.SEMI1.GT.0.0) THEN
          ITERM = -1
          if(rank.eq.0)then
          WRITE (6,20)  ECC, ECC1, SEMI, SEMI1, PMIN, QST*SEMI
   20     FORMAT (' CSTAB2    ECC0 =',F6.3,'  ECC1 =',F6.3,
     &         '  SEMI0[NB] =',1P,E8.1,
     &         '  SEMI1 =',E8.1,'  PERIM =',E9.2,'  QST =',E9.2)
          WRITE (6,25)  NAMEC(I1), NAMEC(I2), ECC0, SEMI0, PMIN0,
     &         PCRIT0, QST
   25     FORMAT (' INNER TRIPLE    NAM E0 A0 PM0 PC0 QST',
     &                              2I6,F7.3,1P,4E10.2)
          end if
          RI = SQRT(CM(1)**2 + CM(2)**2 + CM(3)**2)
          if(rank.eq.0)
     &    WRITE (81,30)  TIMEC, RI, NAMEC(I3), ECC, ECC1, 
     &                   SEMI, SEMI1, PCRIT/PMIN, 180.*ALPHA/3.1415 
   30     FORMAT ('CSTAB2:  TIMEC[NB] RI[NB] NAME(I3) ECC0 ',
     &         'ECC1 SEMI0[NB] SEMI1[NB] PCR/PERIM INA[deg] ',
     &         1P,2E15.6,0P,I12,2F6.2,1P,2E12.4,0P,F12.5,F6.3)
          CALL FLUSH(81)
      END IF
*
   40 RETURN
*
      END
