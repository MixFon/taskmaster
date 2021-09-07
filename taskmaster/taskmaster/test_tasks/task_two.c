#include "stdio.h"

int main(int ac, char **av)
{
	fprintf(stderr, "err two ac = {%d}\n", ac);
	for (int i = 0; i < ac; i++)
		printf("out two ac[%d] = {%s}\n", i, av[i]);
	while(21);
	return 0;
}
