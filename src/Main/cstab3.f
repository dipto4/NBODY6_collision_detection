      SUBROUTINE CSTAB3(ITERM)
*
*
*       Perturbed triple chain stability test.
*       --------------------------------------
*
      INCLUDE 'commonc.h'
      INCLUDE 'common2.h'
      INCLUDE 'mpi_base.h'
      COMMON/CHREG/  TIMEC,TMAX,RMAXC,CM(10),NAMEC(6),NSTEP1,KZ27,KZ30
      REAL*8  M,MB,MB1,R2(NMX,NMX),XCM(3),VCM(3),XX(3,3),VV(3,3)
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
      MB4 = MB1 + M(I4)
*
*       Form output diagnostics.
      VREL2 = 0.0D0
      VREL21 = 0.0D0
      RDOT = 0.0D0
      RDOT3 = 0.0D0
      RI2 = 0.0D0
      R4 = 0.0D0
      V4 = 0.0
      RDOT4 = 0.0D0
      DO 10 K = 1,3
          J1 = 3*(I1-1) + K
          J2 = 3*(I2-1) + K
          J3 = 3*(I3-1) + K
          J4 = 3*(I4-1) + K
          VREL2 = VREL2 + (V(J1) - V(J2))**2
          RDOT = RDOT + (X(J1) - X(J2))*(V(J1) - V(J2))
          XCM(K) = (M(I1)*X(J1) + M(I2)*X(J2))/MB
          VCM(K) = (M(I1)*V(J1) + M(I2)*V(J2))/MB
          RI2 = RI2 + (X(J3) - XCM(K))**2
          VREL21 = VREL21 + (V(J3) - VCM(K))**2
          RDOT3 = RDOT3 + (X(J3) - XCM(K))*(V(J3) - VCM(K))
          XC3 = (M(I3)*X(J3) + MB*XCM(K))/MB1
          VC3 = (M(I3)*V(J3) + MB*VCM(K))/MB1
          R4 = R4 + (X(J4) - XC3)**2
          V4 = V4 + (V(J4) - VC3)**2
          RDOT4 = RDOT4 + (X(J4) - XC3)*(V(J4) - VC3)
          XX(K,1) = X(J1)
          XX(K,2) = X(J2)
          XX(K,3) = X(J3)
          VV(K,1) = V(J1)
          VV(K,2) = V(J2)
          VV(K,3) = V(J3)
   10 CONTINUE
*
*       Evaluate orbital elements for inner and outer motion.
      RB = SQRT(R2(I1,I2))
      R3 = SQRT(RI2)
      SEMI = 2.0D0/RB - VREL2/MB
      SEMI = 1.0/SEMI
      ECC = SQRT((1.0D0 - RB/SEMI)**2 + RDOT**2/(SEMI*MB))
      SEMI1 = 2.0/R3 - VREL21/MB1
      SEMI1 = 1.0/SEMI1
      ECC1 = SQRT((1.0D0 - R3/SEMI1)**2 + RDOT3**2/(SEMI1*MB1))
      R4 = SQRT(R4)
      SEMI4 = 2.0/R4 - V4/MB4
      SEMI4 = 1.0/SEMI4
      ECC4 = SQRT((1.0 - R4/SEMI4)**2 + RDOT4**2/(SEMI4*MB4))
*
*       Form hierarchical stability ratio (Eggleton & Kiseleva 1995).
C      QL = MB/M(I3)
C      Q1 = MAX(M(I2)/M(I1),M(I1)/M(I2))
C      Q3 = QL**0.33333
C      Q13 = Q1**0.33333
C      AR = 1.0 + 3.7/Q3 - 2.2/(1.0 + Q3) + 1.4/Q13*(Q3 - 1.0)/(Q3 + 1.0)
*
C      EK = AR*SEMI*(1.0D0 + ECC)
C      PMIN = SEMI1*(1.0D0 - ECC1)
C*
C*       Replace the EK criterion by the MA analytical stability formula.
C      Q0 = M(I3)/MB
C      IF (ECC1.LT.1.0) THEN
C          XFAC = (1.0 + Q0)*(1.0 + ECC1)/SQRT(1.0 - ECC1)
C      ELSE
C          XFAC = 40.0*(1.0 + Q0)
C      END IF
C      FE = 1.0
C      PCRIT = 2.8*FE*XFAC**0.4*SEMI
C*
*       Obtain the inclination.
      CALL INCLIN(XX,VV,XCM,VCM,ALPHA)
C*
C*       Include fudge factor for inclination effect.
C      YFAC = 1.0 - 0.3*ALPHA/3.14
C      PCRIT = YFAC*PCRIT
*
*       Check hierarchical stability condition for 3 + 1 configuration.
      ITERM = 0
*       Skip if innermost triple is not bound (including ECC & ECC1 > 1).
      IF (SEMI.LT.0.0.OR.ECC.GT.1.0.OR.ECC1.GT.1.0) THEN
          ITERM = 1
          GO TO 40
      END IF
*       Evaluate the Valtonen stability criterion.
      QST = QSTAB(ECC,ECC1,ALPHA,M(I3),M(I4),MB)
      PMIN = SEMI1*(1.0D0 - ECC1)
      IF (QST*SEMI.LT.PMIN) THEN
*       Allow for small theoretical correction factor.
          ZF = ABS(SEMI)/SEMI1
          ZF = MIN(ZF,0.2)
          PCRIT = QST*SEMI*(1.0 + 0.1*ZF)
      ELSE
          ITERM = 1
          GO TO 40
      END IF
      
      IF (PMIN.GT.PCRIT.AND.SEMI1.GT.0.0.AND.SEMI4.GT.0.0.AND.
     &    RB.GT.SEMI) THEN
          G4 = 2.0*M(I4)/MB4*(R3/R4)**3
          PMIN4 = SEMI4*(1.0 - ECC4)
          ZFAC = (1.0 + M(I4)/MB1)*(1.0 + ECC4)/SQRT(1.0 - ECC4)
          ZCRIT = 2.8*FE*ZFAC**0.4*SEMI4
          PZ = PMIN4/ZCRIT
*
*       Ignore outermost body for perturbation test of inner triple.
          IF (N.EQ.5) THEN
              G4 = 2.0*M(I4)/MB1*(R3/PMIN4)**3
              IF (G4.LT.0.1) THEN
                  if(rank.eq.0)
     &            WRITE (6,19)  NSTEP1, ECC4, SEMI, PCRIT, PMIN4, G4
   19             FORMAT (' CSTAB3    # E4 A PCR PM4 G4 ',
     &                                I6,F8.4,1P,4E10.2)
                  ITERM = -1
              END IF
              GO TO 40
          END IF
*
C*       Continue chain integration if outer orbit unstable or large pert.
C          IF (PMIN4.LT.ZCRIT.OR.G4.GT.0.2) GO TO 40
*
          ITERM = -1
          if(rank.eq.0)
     &    WRITE (6,20)  ECC, ECC1, SEMI, SEMI1, PMIN, PCRIT, PZ
   20     FORMAT (' CSTAB3    E =',F6.3,'  E1 =',F6.3,'  A =',1P,E8.1,
     &                     '  A1 =',E8.1,'  PM =',E9.2,'  PC =',E9.2,
     &                     '  P/Z =',0P,F5.2)
          RI = SQRT(CM(1)**2 + CM(2)**2 + CM(3)**2)
          if(rank.eq.0)
     &    WRITE (81,30)  TIMEC, RI, NAMEC(I3), ECC, ECC1, 
     &                   SEMI, SEMI1, PCRIT/PMIN, 180.*ALPHA/3.14
   30     FORMAT ('CSTAB3:  TIMEC[NB] RI[NB] NAME(I3) ECC0 ',
     &         'ECC1 SEMI0[NB] SEMI1[NB] PCR/PERIM INA[deg] ',
     &         1P,2E15.6,0P,I12,2F6.2,1P,2E12.4,0P,F12.5,F6.3)
          CALL FLUSH(81)
      END IF
*
   40 RETURN
*
      END
