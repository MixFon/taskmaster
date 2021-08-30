
#include "stdio.h"

int main(int ac, char **av)
{
	fprintf(stderr, "ac = {%d}\n", ac);
	
	for (int i = 0; i < ac; i++)
		printf("ac[%d] = {%s}\n", i, av[i]);
	return 0;
}
