c      This file contains the direct evaluation kernels for Helmholtz FMM
c
c      h3ddirectcp:  direct calculation of potential for a collection 
c                         of charge sources at a collection of targets
c
c      h3ddirectcg:  direct calculation of potential and gradient 
c                         for a collection of charge sources at a 
c                         collection of targets
c
c      h3ddirectdp:  direct calculation of potential for a collection 
c                         of dipole sources at a collection of targets
c
c      h3ddirectdg:  direct calculation of potential and gradient 
c                         for a collection of dipole sources at a 
c                         collection of targets
c
c      h3ddirectcdp:  direct calculation of potential for a 
c                         collection of charge and dipole sources at 
c                         a collection of targets
c
c      h3ddirectcdg:  direct calculation of potential 
c                         and gradient for a collection 
c                         of charge and dipole sources at a 
c                         collection of targets
c
c
c
c
c
C***********************************************************************
      subroutine h3ddirectcp(nd,zk,sources,charge,ns,ztarg,nt,
     1            pot,thresh)
c**********************************************************************
c
c     This subroutine evaluates the potential due to a collection
c     of sources and adds to existing
c     quantities.
c
c     pot(x) = pot(x) + sum  q_{j} e^{i k |x-x_{j}|}/|x-x_{j}| 
c                        j
c                 
c      where q_{j} is the charge strength
c      If |r| < thresh 
c          then the subroutine does not update the potential
c          (recommended value = boxsize(0)*machine precision
c           for boxsize(0) is the size of the computational domain) 
c
c
c-----------------------------------------------------------------------
c     INPUT:
c
c     nd     :    number of charge densities
c     zk     :    Helmholtz parameter
c     sources:    source locations
C     charge :    charge strengths
C     ns     :    number of sources
c     ztarg  :    target locations
c     ntarg  :    number of targets
c     thresh :    threshold for updating potential,
c                 potential at target won't be updated if
c                 |t - s| <= thresh, where t is the target
c                 location and, and s is the source location 
c                 
c-----------------------------------------------------------------------
c     OUTPUT:
c
c     pot    :    updated potential at ztarg 
c
c-----------------------------------------------------------------------
      implicit none
cf2py intent(in) nd,zk,sources,charge,ns,ztarg,nt,thresh
cf2py intent(out) pot

c
cc      calling sequence variables
c  
      integer ns,nt,nd
      complex *16 zk
      real *8 sources(3,ns),ztarg(3,nt)
      complex *16 charge(nd,ns),pot(nd,nt)
      real *8 thresh
      
c
cc     temporary variables
c
      real *8 zdiff(3),dd,d
      complex *16 zkeye,eye,ztmp
      integer i,j,idim
      data eye/(0.0d0,1.0d0)/

      zkeye = zk*eye

c$omp parallel do default(shared) 
c$omp$     private(i, zdiff, j, dd, d, ztmp, idim)
      do i=1,nt
        do j=1,ns
          zdiff(1) = ztarg(1,i)-sources(1,j)
          zdiff(2) = ztarg(2,i)-sources(2,j)
          zdiff(3) = ztarg(3,i)-sources(3,j)

          dd = zdiff(1)**2 + zdiff(2)**2 + zdiff(3)**2
          d = sqrt(dd)
          if(d.lt.thresh) goto 1000

          ztmp = exp(zkeye*d)/d
          do idim=1,nd
            pot(idim,i) = pot(idim,i) + charge(idim,j)*ztmp
          enddo
 1000     continue
        enddo
      enddo
c$omp end parallel do      


      return
      end
c
c
c
c
c
c
C***********************************************************************
      subroutine h3ddirectcg(nd,zk,sources,charge,ns,ztarg,nt,
     1            pot,grad,thresh)
c**********************************************************************
c
c     This subroutine evaluates the potential and gradient due to a 
c     collection of sources and adds to existing quantities.
c
c     pot(x) = pot(x) + sum  q_{j} e^{i k |x-x_{j}|}/|x-x_{j}| 
c                        j
c                 
c     grad(x) = grad(x) + Gradient(sum  q_{j} e^{i k |x-x_{j}|}/|x-x_{j}|) 
c                                   j
c      where q_{j} is the charge strength
c      If |r| < thresh 
c          then the subroutine does not update the potential
c          (recommended value = boxsize(0)*machine precision
c           for boxsize(0) is the size of the computational domain) 
c
c
c-----------------------------------------------------------------------
c     INPUT:
c
c     nd     :    number of charge densities
c     zk     :    Helmholtz parameter
c     sources:    source locations
C     charge :    charge strengths
C     ns     :    number of sources
c     ztarg  :    target locations
c     ntarg  :    number of targets
c     thresh :    threshold for updating potential,
c                 potential at target won't be updated if
c                 |t - s| <= thresh, where t is the target
c                 location and, and s is the source location 
c                 
c-----------------------------------------------------------------------
c     OUTPUT:
c
c     pot    :    updated potential at ztarg 
c     grad   :    updated gradient at ztarg 
c
c-----------------------------------------------------------------------
      implicit none
cf2py intent(in) nd,zk,sources,charge,ns,ztarg,nt,thresh
cf2py intent(out) pot,grad

c
cc      calling sequence variables
c  
      integer ns,nt,nd
      complex *16 zk
      real *8 sources(3,ns),ztarg(3,nt)
      complex *16 charge(nd,ns),pot(nd,nt),grad(nd,3,nt)
      real *8 thresh
      
c
cc     temporary variables
c
      real *8 zdiff(3),dd,d
      complex *16 zkeye,eye,cd,cd1,ztmp
      complex *16 ztmp1,ztmp2,ztmp3
      integer i,j,idim
      data eye/(0.0d0,1.0d0)/

      zkeye = zk*eye

c$omp parallel do default(shared)
c$omp$    private(i, j, zdiff, dd, d, cd, cd1, ztmp1)
c$omp$    private(ztmp2, ztmp3, idim)
      do i=1,nt
        do j=1,ns
          zdiff(1) = ztarg(1,i)-sources(1,j)
          zdiff(2) = ztarg(2,i)-sources(2,j)
          zdiff(3) = ztarg(3,i)-sources(3,j)

          dd = zdiff(1)**2 + zdiff(2)**2 + zdiff(3)**2
          d = sqrt(dd)
          if(d.lt.thresh) goto 1000
          cd = exp(zkeye*d)/d
          cd1 = (zkeye*d-1)*cd/dd
          ztmp1 = cd1*zdiff(1)
          ztmp2 = cd1*zdiff(2)
          ztmp3 = cd1*zdiff(3)
          do idim=1,nd
            pot(idim,i) = pot(idim,i) + cd*charge(idim,j)
            grad(idim,1,i) = grad(idim,1,i) + ztmp1*charge(idim,j)
            grad(idim,2,i) = grad(idim,2,i) + ztmp2*charge(idim,j)
            grad(idim,3,i) = grad(idim,3,i) + ztmp3*charge(idim,j)
          enddo
 1000     continue
        enddo
      enddo
c$omp end parallel do      


      return
      end
c
c
c
c
c
c
c
C***********************************************************************
      subroutine h3ddirectdp(nd,zk,sources,
     1            dipvec,ns,ztarg,nt,pot,thresh)
c**********************************************************************
c
c     This subroutine evaluates the potential due to a collection
c     of sources and adds to existing
c     quantities.
c
c     pot(x) = pot(x) + sum   \nabla e^{ik |x-x_{j}|/|x-x_{j}| \cdot v_{j} 
c                        j
c
c                            
c   
c      where v_{j} is the dipole orientation vector, 
c      \nabla denotes the gradient is with respect to the x_{j} 
c      variable 
c      If |r| < thresh 
c          then the subroutine does not update the potential
c          (recommended value = boxsize(0)*machine precision
c           for boxsize(0) is the size of the computational domain) 
c
c
c-----------------------------------------------------------------------
c     INPUT:
c
c     nd     :    number of charge and dipole densities
c     zk     :    Helmholtz parameter
c     sources:    source locations
C     dipvec :    dipole orientation vectors
C     ns     :    number of sources
c     ztarg  :    target locations
c     ntarg  :    number of targets
c     thresh :    threshold for updating potential,
c                 potential at target won't be updated if
c                 |t - s| <= thresh, where t is the target
c                 location and, and s is the source location 
c                 
c-----------------------------------------------------------------------
c     OUTPUT:
c
c     pot    :    updated potential at ztarg 
c
c-----------------------------------------------------------------------
      implicit none
cf2py intent(in) nd,zk,sources,dipvec,ns,ztarg,nt,thresh
cf2py intent(out) pot

c
cc      calling sequence variables
c  
      integer ns,nt,nd
      complex *16 zk
      real *8 sources(3,ns),ztarg(3,nt)
      complex *16 dipvec(nd,3,ns)
      complex *16 pot(nd,nt)
      real *8 thresh
      
c
cc     temporary variables
c
      real *8 zdiff(3),dd,d,dinv
      complex *16 zkeye,eye,cd,cd1,dotprod
      integer i,j,idim
      data eye/(0.0d0,1.0d0)/

      zkeye = zk*eye

c$omp parallel do default(shared)
c$omp$   private(i, j, zdiff, dd, d, dinv, cd, cd1, idim, dotprod)
      do i=1,nt
        do j=1,ns
          zdiff(1) = ztarg(1,i)-sources(1,j)
          zdiff(2) = ztarg(2,i)-sources(2,j)
          zdiff(3) = ztarg(3,i)-sources(3,j)

          dd = zdiff(1)**2 + zdiff(2)**2 + zdiff(3)**2
          d = sqrt(dd)
          if(d.lt.thresh) goto 1000

          dinv = 1/d
          cd = exp(zkeye*d)*dinv
          cd1 = (1-zkeye*d)*cd/dd

          do idim=1,nd
            dotprod = zdiff(1)*dipvec(idim,1,j) + 
     1          zdiff(2)*dipvec(idim,2,j)+
     1          zdiff(3)*dipvec(idim,3,j)
            pot(idim,i) = pot(idim,i) + cd1*dotprod
          enddo

 1000     continue
        enddo
      enddo
c$omp end parallel do      


      return
      end
c
c
c
c
c
c
C***********************************************************************
      subroutine h3ddirectdg(nd,zk,sources,dipvec,ns,ztarg,nt,pot,
     1   grad,thresh)
c**********************************************************************
c
c     This subroutine evaluates the potential and gradient due to a 
c     collection of sources and adds to existing quantities.
c
c     pot(x) = pot(x) + sum  d_{j} \nabla e^{ik |x-x_{j}|/|x-x_{j}| \cdot v_{j}
c                        j
c
c                            
c   
c     grad(x) = grad(x) + Gradient( sum  
c                                    j
c
c                            \nabla e^{ik |x-x_{j}|/|x-x_{j}| \cdot v_{j}
c                            )
c                                   
c      where v_{j} is the dipole orientation vector, 
c      \nabla denotes the gradient is with respect to the x_{j} 
c      variable, and Gradient denotes the gradient with respect to
c      the x variable
c      If r < thresh 
c          then the subroutine does not update the potential
c          (recommended value = boxsize(0)*machine precision
c           for boxsize(0) is the size of the computational domain) 
c
c
c-----------------------------------------------------------------------
c     INPUT:
c
c     nd     :    number of charge and dipole densities
c     zk     :    Helmholtz parameter
c     sources:    source locations
C     dipvec :    dipole orientation vector
C     ns     :    number of sources
c     ztarg  :    target locations
c     ntarg  :    number of targets
c     thresh :    threshold for updating potential,
c                 potential at target won't be updated if
c                 |t - s| <= thresh, where t is the target
c                 location and, and s is the source location 
c                 
c-----------------------------------------------------------------------
c     OUTPUT:
c
c     pot    :    updated potential at ztarg 
c     grad   :    updated gradient at ztarg 
c
c-----------------------------------------------------------------------
      implicit none
cf2py intent(in) nd,zk,sources,dipvec,ns,ztarg,nt,thresh
cf2py intent(out) pot,grad

c
cc      calling sequence variables
c  
      integer ns,nt,nd
      complex *16 zk
      real *8 sources(3,ns),ztarg(3,nt)
      complex *16 dipvec(nd,3,ns)
      complex *16 pot(nd,nt),grad(nd,3,nt)
      real *8 thresh
      
c
cc     temporary variables
c
      real *8 zdiff(3),dd,d,dinv,dinv2
      complex *16 zkeye,eye,cd,cd2,cd3,cd4,dotprod
      integer i,j,idim
      data eye/(0.0d0,1.0d0)/

      zkeye = zk*eye

c$omp parallel do default(shared)
c$omp$   private(i, j, zdiff, dd, d, dinv, dinv2, cd, cd2)
c$omp$   private(cd3, idim, dotprod, cd4)      
      do i=1,nt
        do j=1,ns
          zdiff(1) = ztarg(1,i)-sources(1,j)
          zdiff(2) = ztarg(2,i)-sources(2,j)
          zdiff(3) = ztarg(3,i)-sources(3,j)

          dd = zdiff(1)**2 + zdiff(2)**2 + zdiff(3)**2
          d = sqrt(dd)
          if(d.lt.thresh) goto 1000

          dinv = 1/d
          dinv2 = dinv**2
          cd = exp(zkeye*d)*dinv
          cd2 = (zkeye*d-1)*cd*dinv2
          cd3 = cd*dinv2*(-zkeye*zkeye-3*dinv2+3*zkeye*dinv)

          do idim=1,nd
          
            dotprod = zdiff(1)*dipvec(idim,1,j)+
     1               zdiff(2)*dipvec(idim,2,j)+
     1               zdiff(3)*dipvec(idim,3,j)
            cd4 = cd3*dotprod

            pot(idim,i) = pot(idim,i) - cd2*dotprod
            grad(idim,1,i) = grad(idim,1,i) + (cd4*zdiff(1) - 
     1         cd2*dipvec(idim,1,j)) 
            grad(idim,2,i) = grad(idim,2,i) + (cd4*zdiff(2) - 
     1         cd2*dipvec(idim,2,j))
            grad(idim,3,i) = grad(idim,3,i) + (cd4*zdiff(3) - 
     1         cd2*dipvec(idim,3,j))
          enddo
 1000     continue
        enddo
      enddo
c$omp end parallel do      


      return
      end
c
c
c
c
C***********************************************************************
      subroutine h3ddirectcdp(nd,zk,sources,charge,
     1            dipvec,ns,ztarg,nt,pot,thresh)
c**********************************************************************
c
c     This subroutine evaluates the potential due to a collection
c     of sources and adds to existing
c     quantities.
c
c     pot(x) = pot(x) + sum  q_{j} e^{i k |x-x_{j}|}/|x-x_{j}| +  
c                        j
c
c                            \nabla e^{ik |x-x_{j}|/|x-x_{j}| \cdot v_{j}
c   
c      where q_{j} is the charge strength, 
c      and v_{j} is the dipole orientation vector, 
c      \nabla denotes the gradient is with respect to the x_{j} 
c      variable 
c      If r < thresh 
c          then the subroutine does not update the potential
c          (recommended value = boxsize(0)*machine precision
c           for boxsize(0) is the size of the computational domain) 
c
c
c-----------------------------------------------------------------------
c     INPUT:
c
c     nd     :    number of charge and dipole densities
c     zk     :    Helmholtz parameter
c     sources:    source locations
C     charge :    charge strengths
C     dipvec :    dipole orientation vectors
C     ns     :    number of sources
c     ztarg  :    target locations
c     ntarg  :    number of targets
c     thresh :    threshold for updating potential,
c                 potential at target won't be updated if
c                 |t - s| <= thresh, where t is the target
c                 location and, and s is the source location 
c                 
c-----------------------------------------------------------------------
c     OUTPUT:
c
c     pot    :    updated potential at ztarg 
c
c-----------------------------------------------------------------------
      implicit none
cf2py intent(in) nd,zk,sources,charge,dipvec,ns,ztarg,nt,thresh
cf2py intent(out) pot
c
c
cc      calling sequence variables
c  
      integer ns,nt,nd
      complex *16 zk
      real *8 sources(3,ns),ztarg(3,nt)
      complex *16 dipvec(nd,3,ns)
      complex *16 charge(nd,ns),pot(nd,nt)
      real *8 thresh
      
c
cc     temporary variables
c
      real *8 zdiff(3),dd,d,dinv
      complex *16 zkeye,eye,cd,cd1,dotprod
      integer i,j,idim
      data eye/(0.0d0,1.0d0)/

      zkeye = zk*eye

c$omp parallel do default(shared)
c$omp$    private(i, j, zdiff, dd, d, dinv, cd, cd1, idim, dotprod)
      do i=1,nt
        do j=1,ns
          zdiff(1) = ztarg(1,i)-sources(1,j)
          zdiff(2) = ztarg(2,i)-sources(2,j)
          zdiff(3) = ztarg(3,i)-sources(3,j)

          dd = zdiff(1)**2 + zdiff(2)**2 + zdiff(3)**2
          d = sqrt(dd)
          if(d.lt.thresh) goto 1000

          dinv = 1/d
          cd = exp(zkeye*d)*dinv
          cd1 = (1-zkeye*d)*cd/dd

          do idim=1,nd
            pot(idim,i) = pot(idim,i) + charge(idim,j)*cd

            dotprod = zdiff(1)*dipvec(idim,1,j) + 
     1          zdiff(2)*dipvec(idim,2,j)+
     1          zdiff(3)*dipvec(idim,3,j)
            pot(idim,i) = pot(idim,i) + cd1*dotprod
          enddo

 1000     continue
        enddo
      enddo
c$omp end parallel do      



      return
      end
c
c
c
c
c
c
C***********************************************************************
      subroutine h3ddirectcdg(nd,zk,sources,charge,
     1            dipvec,ns,ztarg,nt,pot,grad,thresh)
c**********************************************************************
c
c     This subroutine evaluates the potential and gradient due to a 
c     collection of sources and adds to existing quantities.
c
c     pot(x) = pot(x) + sum  q_{j} e^{i k |x-x_{j}|}/|x-x_{j}| +  
c                        j
c
c                            \nabla e^{ik |x-x_{j}|/|x-x_{j}| \cdot v_{j}
c   
c     grad(x) = grad(x) + Gradient( sum  q_{j} e^{i k |x-x_{j}|}/|x-x_{j}| +  
c                                    j
c
c                            d_{j} \nabla e^{ik |x-x_{j}|/|x-x_{j}| \cdot v_{j}
c                            )
c                                   
c      where q_{j} is the charge strength
c      and v_{j} is the dipole orientation vector, 
c      \nabla denotes the gradient is with respect to the x_{j} 
c      variable, and Gradient denotes the gradient with respect to
c      the x variable
c      If r < thresh 
c          then the subroutine does not update the potential
c          (recommended value = boxsize(0)*machine precision
c           for boxsize(0) is the size of the computational domain) 
c
c
c-----------------------------------------------------------------------
c     INPUT:
c
c     nd     :    number of charge and dipole densities
c     zk     :    Helmholtz parameter
c     sources:    source locations
C     charge :    charge strengths
C     dipvec :    dipole orientation vector
C     ns     :    number of sources
c     ztarg  :    target locations
c     ntarg  :    number of targets
c     thresh :    threshold for updating potential,
c                 potential at target won't be updated if
c                 |t - s| <= thresh, where t is the target
c                 location and, and s is the source location 
c                 
c-----------------------------------------------------------------------
c     OUTPUT:
c
c     pot    :    updated potential at ztarg 
c     grad   :    updated gradient at ztarg 
c
c-----------------------------------------------------------------------
      implicit none
cf2py intent(in) nd,zk,sources,charge,dipvec,ns,ztarg,nt,thresh
cf2py intent(out) pot,grad
c
cc      calling sequence variables
c  
      integer ns,nt,nd
      complex *16 zk
      real *8 sources(3,ns),ztarg(3,nt)
      complex *16 dipvec(nd,3,ns)
      complex *16 charge(nd,ns),pot(nd,nt),grad(nd,3,nt)
      real *8 thresh
      
c
cc     temporary variables
c
      real *8 zdiff(3),dd,d,dinv,dinv2
      complex *16 zkeye,eye,cd,cd2,cd3,cd4,dotprod
      integer i,j,idim
      data eye/(0.0d0,1.0d0)/

      zkeye = zk*eye

c$omp parallel do default(shared)
c$omp$   private(i, j, zdiff, dd, d, dinv, dinv2, cd, cd2, cd3)
c$omp$   private(idim, dotprod, cd4)      
      do i=1,nt
        do j=1,ns
          zdiff(1) = ztarg(1,i)-sources(1,j)
          zdiff(2) = ztarg(2,i)-sources(2,j)
          zdiff(3) = ztarg(3,i)-sources(3,j)

          dd = zdiff(1)**2 + zdiff(2)**2 + zdiff(3)**2
          d = sqrt(dd)
          if(d.lt.thresh) goto 1000

          dinv = 1/d
          dinv2 = dinv**2
          cd = exp(zkeye*d)*dinv
          cd2 = (zkeye*d-1)*cd*dinv2
          cd3 = cd*dinv2*(-zkeye*zkeye-3*dinv2+3*zkeye*dinv)

          do idim=1,nd
          
            pot(idim,i) = pot(idim,i) + cd*charge(idim,j)
            dotprod = zdiff(1)*dipvec(idim,1,j)+
     1               zdiff(2)*dipvec(idim,2,j)+
     1               zdiff(3)*dipvec(idim,3,j)
            cd4 = cd3*dotprod

            pot(idim,i) = pot(idim,i) - cd2*dotprod
            grad(idim,1,i) = grad(idim,1,i) + (cd4*zdiff(1) - 
     1         cd2*dipvec(idim,1,j))
     2         + cd2*charge(idim,j)*zdiff(1) 
            grad(idim,2,i) = grad(idim,2,i) + (cd4*zdiff(2) - 
     1         cd2*dipvec(idim,2,j))
     2         + cd2*charge(idim,j)*zdiff(2) 
            grad(idim,3,i) = grad(idim,3,i) + (cd4*zdiff(3) - 
     1         cd2*dipvec(idim,3,j))
     2         + cd2*charge(idim,j)*zdiff(3)
          enddo
 1000     continue
        enddo
      enddo
c$omp end parallel do      


      return
      end
