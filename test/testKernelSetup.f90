program testKernelSetup
!! Focal test program
!!
!! This test launches simple kernels which set int/float/double device buffers
!!  then transfers the buffers to host and verifies the contents of them.

use Focal
use Focal_Test_Utils
use iso_fortran_env, only: sp=>real32, dp=>real64
implicit none

character(:), allocatable :: kernelSrc              ! Kernel source string
type(fclProgram) :: prog                            ! Focal program object
type(fclKernel) :: setInt_k, setFloat_k, setDouble_k, setChar_k

real(sp), dimension(FCL_TEST_SIZE) :: hostReal32
real(dp), dimension(FCL_TEST_SIZE) :: hostReal64
integer, dimension(FCL_TEST_SIZE) :: hostInt32
character(1), dimension(FCL_TEST_SIZE), target :: hostChar

type(fclDeviceFloat) :: deviceReal32
type(fclDeviceDouble) :: deviceReal64
type(fclDeviceInt32) :: deviceInt32
type(fclDeviceBuffer) :: deviceBuffer

integer :: i, fh
logical :: fExist

! --- Initialise ---
!  Use fclInit here (mode=2)
call fclTestInit(mode=2)

! --- Initialise device buffers ---
call fclInitBuffer(deviceInt32,FCL_TEST_SIZE)
call fclInitBuffer(deviceReal32,FCL_TEST_SIZE)
call fclInitBuffer(deviceReal64,FCL_TEST_SIZE)
call fclInitBuffer(deviceBuffer,c_sizeof(hostChar))

! --- Initialise kernels ---
call fclGetKernelResource(kernelSrc)
prog = fclCompileProgram(kernelSrc)

! --- Dump build log to file and check ---
open(newunit=fh,file='testBuildLog',status='unknown')
call fclDumpBuildLog(prog,ocl_device,fh)
close(fh)
INQUIRE(FILE='testBuildLog', EXIST=fExist)
call fclTestAssert(fExist,'Build log file exists')
if (fExist) then
    open(newunit=fh,file='testBuildLog',status='old')
    close(fh,status='delete')
end if

setInt_k = fclGetProgramKernel(prog,'setInt32Test',[FCL_TEST_SIZE])
setFloat_k = fclGetProgramKernel(prog,'setFloatTest',[FCL_TEST_SIZE])
setDouble_k = fclGetProgramKernel(prog,'setDoubleTest',[FCL_TEST_SIZE])
setChar_k = fclGetProgramKernel(prog,'setCharTest',[FCL_TEST_SIZE])

! --- Call kernels ---
call fclLaunchKernel(setInt_k,FCL_TEST_SIZE,deviceInt32)
call fclLaunchKernel(setFloat_k,FCL_TEST_SIZE,deviceReal32)
call fclLaunchKernel(setDouble_k,FCL_TEST_SIZE,deviceReal64)
call fclLaunchKernel(setChar_k,FCL_TEST_SIZE,deviceBuffer)

! --- Transfer device buffers to host ---
hostInt32 = deviceInt32
hostReal32 = deviceReal32
hostReal64 = deviceReal64

call fclMemRead(c_loc(hostChar),deviceBuffer,c_sizeof(hostChar))


! --- Check arrays ---
call fclTestAssertEqual([sum(hostInt32)],[sum([(i,i=0,FCL_TEST_SIZE-1)])],'sum(hostInt32)')
call fclTestAssertEqual([sum(hostReal32)],[sum([(1.0*i,i=0,FCL_TEST_SIZE-1)])],'sum(hostReal32)')
call fclTestAssertEqual([sum(hostReal64)],[sum([(1.0d0*i,i=0,FCL_TEST_SIZE-1)])],'sum(hostReal64)')
call fclTestAssertEqual(hostChar,[('a',i=0,FCL_TEST_SIZE-1)],'hostChar')

call fclFreeBuffer(deviceInt32)
call fclFreeBuffer(deviceReal32)
call fclFreeBuffer(deviceReal64)
call fclFreeBuffer(deviceBuffer)

call fclTestFinish()

end program testKernelSetup
! -----------------------------------------------------------------------------
