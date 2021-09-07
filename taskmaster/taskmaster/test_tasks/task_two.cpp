
#include "stdio.h"
#include <iostream>

using namespace std;

int main(int ac, char **av)
{
	std::cerr << "stderr two ac = [" << ac << "]\n";
	for (int i = 0; i < ac; i++)
		cout << "[" << av[i] << "]" << endl;
	while(21);
	return 0;
}
