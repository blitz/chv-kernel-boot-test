#include <stdio.h>
#include <unistd.h>
#include <sys/reboot.h>


int main()
{
  puts("HELLO WORLD");
  reboot(RB_POWER_OFF);

  while (1) { sleep(3600); }
}
