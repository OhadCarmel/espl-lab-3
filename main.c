#include "Util.h"
#include <dirent.h>

#define SYS_WRITE 4
#define STDOUT 1
#define SYS_OPEN 5
#define O_RDWR 2
#define SYS_SEEK 19
#define SEEK_SET 0
#define SHIRA_OFFSET 0x291
#define O_RDONLY 0
#define O_DIRECTORY 00200000
#define SYS_GETDENTS 141
#define EXIT_SUCCESS 0
#define EXIT_FAILURE 0x55


extern int system_call();

struct linux_dirent {                   /* we used this struck from the getdents man page :-)*/
               unsigned long  d_ino;     /* Inode number */
               unsigned long  d_off;     /* Offset to next linux_dirent */
               unsigned short d_reclen;  /* Length of this linux_dirent */
               char           d_name[];  /* Filename (null-terminated) */        
           };


void printString(char *msg)
{
  system_call(SYS_WRITE, STDOUT, msg, strlen(msg));
  system_call(SYS_WRITE, STDOUT, "\n", 1);
}



#define BUF_SIZE 8192

int main(int argc, char *argv[])
{
  int fd, nread;
  char buf[BUF_SIZE];
  struct linux_dirent *d;
  int bpos;

  fd = system_call(SYS_OPEN, ".", O_RDONLY | O_DIRECTORY);
  if (fd == -1)
    return EXIT_FAILURE;

  
  nread = system_call(SYS_GETDENTS, fd, buf, BUF_SIZE);
  if (nread == -1)
    return EXIT_FAILURE;

  for (bpos = 0; bpos < nread;)
  {
    d = (struct linux_dirent *)(buf + bpos );
    printString(d->d_name);
    bpos += d->d_reclen ;
  }


  return EXIT_SUCCESS;
}