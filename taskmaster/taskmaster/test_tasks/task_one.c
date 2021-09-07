
#include "stdio.h"

int main(int ac, char **av)
{
	
	for (int i = 0; i < ac; i++)
		printf("out one ac[%d] = {%s}\n", i, av[i]);
	fprintf(stderr, "err one ac = {%d}\n", ac);
	while(21);
	return 0;
}
