      SUBROUTINE SEARCH(I,IKS)
*
*
*       Close encounter search.
*       -----------------------
*
      INCLUDE 'common6.h'
      COMMON/CLUMP/   BODYS(NCMAX,5),T0S(5),TS(5),STEPS(5),RMAXS(5),
     &                NAMES(NCMAX,5),ISYS(5)
      REAL*8 RJMIN2
*     Trace flag for debug
      INTEGER TRACE_FLAG
*     1. JCOMP<IFIRST || JCOMP>N
*     2. RJMIN2 > RMIN2
*     3. RDOT > 0.02*sqrt(BODY(I)+BODY(JCOMP)*RIJMIN)
*     4. GI>0.25
*     5. sub: NAMEI==NAME(I) || NAMEI==NAME(JCOMP)
*     6. ch: NAME(I)==0 || NAME(JCOMP)==0
*
      RJMIN2 = RMIN2 + RMIN2
      DTS = MAX(SMIN,32.0*STEP(I))
*
*       Increase counter for regularization attempts.
      NKSTRY = NKSTRY + 1
*
*       Predict body #I to order FDOT for parallel prediction (not active RSp).
      call jpred(i,time,time)
c$$$      if(TPRED(I).ne.TIME) then
c$$$*         print*,rank,'Nopred in search',I
c$$$         S = TIME - T0(I)
c$$$         DO 1 K = 1,3
c$$$             X(K,I) = ((FDOT(K,I)*S + F(K,I))*S + X0DOT(K,I))*S +
c$$$     &                                                           X0(K,I)
c$$$             XDOT(K,I) = (3.0*FDOT(K,I)*S + 2.0*F(K,I))*S + X0DOT(K,I)
c$$$   1     CONTINUE
c$$$      end if
*
      FMAX = 0.0
      NCLOSE = 0
*       Find dominant neighbour by selecting all STEP(J) < 2*DTMIN.
      L = LIST(1,I) + 2
    2 L = L - 1
      IF (L.LT.2) GO TO 10
*
*       First see whether any c.m. with small step is within 2*RMIN.
      IF (LIST(L,I).LE.N) GO TO 4
*
      J = LIST(L,I)
*      IF (STEP(J).GT.SMIN) GO TO 2
C       IF (STEP(J).GT.4*STEP(I).AND.BODY(J).LT.10*BODY(I)) GO TO 2
       IF (STEP(J).GT.DTS) GO TO 2
*       Prediction body #J to order FDOT for parallel prediction (not active RSp).
       call jpred(j,time,time)
c$$$      if(TPRED(J).ne.TIME) then
c$$$*         print*,rank,'Nopred in searchj',J
c$$$         S = TIME - T0(J)
c$$$         DO 225 K = 1,3
c$$$             X(K,J) = ((FDOT(K,J)*S + F(K,J))*S + X0DOT(K,J))*S +
c$$$     &                                                           X0(K,J)
c$$$             XDOT(K,J) = (3.0*FDOT(K,J)*S + 2.0*F(K,J))*S + X0DOT(K,J)
c$$$  225     CONTINUE
c$$$       end if
      A1 = X(1,J) - X(1,I)
      A2 = X(2,J) - X(2,I)
      A3 = X(3,J) - X(3,I)
      RIJ2 = A1*A1 + A2*A2 + A3*A3
      IF (RIJ2.GT.4.0*RMIN22) GO TO 2
*
      FIJ = (BODY(I)+BODY(J))/RIJ2
      IF (FMAX.LT.FIJ) FMAX = FIJ
*       Abandon further search if c.m. force exceeds half the total force.
      IF (FMAX.LE.FIJ) THEN
C      IF (FMAX**2.LT.F(1,I)**2 + F(2,I)**2 + F(3,I)**2) THEN
          NCLOSE = NCLOSE + 1
          JLIST(NCLOSE) = J
C          GO TO 2
C      ELSE
C          GO TO 10
      END IF
      GO TO 2
*
*       Continue searching single particles with current value of FMAX.
    4 JCOMP = 0
*
      DO 6 K = L,2,-1
          J = LIST(K,I)
*          IF (STEP(J).GT.SMIN) GO TO 6
          IF (STEP(J).GT.8*STEP(I)) GO TO 6
*       Prediction body #J to order FDOT for parallel prediction (not active RSp).
          call jpred(j,time,time)
c$$$          if(TPRED(J).ne.TIME) then
c$$$*             print*,rank,'Nopred in searchj2',j
c$$$         S = TIME - T0(J)
c$$$         DO 65 KK = 1,3
c$$$         X(KK,J) = ((FDOT(KK,J)*S + F(KK,J))*S + X0DOT(KK,J))*S +
c$$$     &                                                         X0(KK,J)
c$$$         XDOT(KK,J) = (3.0*FDOT(KK,J)*S + 2.0*F(KK,J))*S + X0DOT(KK,J)
c$$$  65     CONTINUE
c$$$          end if
          A1 = X(1,J) - X(1,I)
          A2 = X(2,J) - X(2,I)
          A3 = X(3,J) - X(3,I)
          RIJ2 = A1*A1 + A2*A2 + A3*A3
          IF (RIJ2.LT.10*RMIN22) THEN
              NCLOSE = NCLOSE + 1
              JLIST(NCLOSE) = J
*       Remember index of every single body with small step inside 2*RMIN.
              FIJ = (BODY(I) + BODY(J))/RIJ2
              IF (FIJ.GT.FMAX) THEN
                  FMAX = FIJ
*       Save square distance and global index of dominant body.
                  RJMIN2 = RIJ2
                  JCOMP = J
              END IF
          END IF
    6 CONTINUE
*
*       See whether dominant component is a single particle inside RMIN.
      IF (JCOMP.LT.IFIRST.OR.JCOMP.GT.N) THEN
         TRACE_FLAG = 1
         GO TO 10
      END IF
      IF (RJMIN2.GT.RMIN2) THEN
         TRACE_FLAG = 2
         GO TO 10
      END IF
*
      RDOT = (X(1,I) - X(1,JCOMP))*(XDOT(1,I) - XDOT(1,JCOMP)) +
     &       (X(2,I) - X(2,JCOMP))*(XDOT(2,I) - XDOT(2,JCOMP)) +
     &       (X(3,I) - X(3,JCOMP))*(XDOT(3,I) - XDOT(3,JCOMP))
*
*       Only select approaching particles (include nearly circular case).
      RIJMIN = SQRT(RJMIN2)
      IF (RDOT.GT.0.02*SQRT((BODY(I) + BODY(JCOMP))*RIJMIN)) THEN
         TRACE_FLAG = 3
         GO TO 10
      END IF
*
*       Ensure a massive neighbour is included in perturbation estimate.
      BCM = BODY(I) + BODY(JCOMP)
      IF (BODY1.GT.10.0*BCM) THEN
          JBIG = 0
          BIG = BCM
          NNB1 = LIST(1,I) + 1
          DO 20 L = 2,NNB1
              J = LIST(L,I)
              IF (BODY(J).GT.BIG) THEN
                  JBIG = J
                  BIG = BODY(J)
              END IF
   20     CONTINUE
*       Check whether already present, otherwise add to JLIST.
          DO 25 L = 1,NCLOSE
              IF (JLIST(L).EQ.JBIG) THEN
                  JBIG = 0
              END IF
   25     CONTINUE
          IF (JBIG.GT.0) THEN
              NCLOSE = NCLOSE + 1
              JLIST(NCLOSE) = JBIG
          END IF
      END IF
*
*       Evaluate vectorial perturbation due to the close bodies.
      CALL FPERT(I,JCOMP,NCLOSE,PERT)
*
*       Accept #I & JCOMP if the relative motion is dominant (GI < 0.25).
      GI = PERT*RJMIN2/BCM
      IF (GI.GT.0.01) THEN
*         IF (KZ(4).GT.0.AND.TIME-TLASTT.GT.4.44*TCR/FLOAT(N))
*    &                                             CALL EVOLVE(JCOMP,0)
          TRACE_FLAG=4
          GO TO 10
      END IF
*
*       Exclude any c.m. body of compact subsystem (TRIPLE, QUAD or CHAIN).
      DO 8 ISUB = 1,NSUB
          NAMEI = NAMES(1,ISUB)
          IF (NAMEI.EQ.NAME(I).OR.NAMEI.EQ.NAME(JCOMP)) THEN
             TRACE_FLAG=5
             GO TO 10
          END IF
    8 CONTINUE
*
*       Also check possible c.m. body of chain regularization (NAME = 0).
      IF (NCH.GT.0) THEN
          IF (NAME(I).EQ.0.OR.NAME(JCOMP).EQ.0) THEN
             TRACE_FLAG=6
             GO TO 10
          END IF
      END IF
*
*       Save index and increase indicator to denote new regularization.
      ICOMP = I
      IKS = IKS + 1

 10   CONTINUE

*     --07/19/14 22:42-lwang-debug--------------------------------------*
***** Note:------------------------------------------------------------**
C      print*,'SEARCH I',I,'NB',LIST(1,I),'L',LIST(2:LIST(1,I),I),
C     &     'TRACE_F',TRACE_FLAG,'IKS',IKS,'JCOMP',JCOMP
*     --07/19/14 22:42-lwang-end----------------------------------------*
*
      
      RETURN
*
      END
