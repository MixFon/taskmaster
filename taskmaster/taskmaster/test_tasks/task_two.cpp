
#include "stdio.h"
#include <iostream>
#include <ctime>
#include <unistd.h>

using namespace std;

int main(int ac, char **av)
{
	std::cerr << "stderr two ac = [" << ac << "]\n";
	for (int i = 0; i < ac; i++)
	{
		time_t now = time(0);
		cout << "{" << av[i] << "} " << now << endl;
	}
	while(21) {
		time_t now = time(0);
		sleep(2);
		cout << "{" << now << "}" << endl;
	}
	return 0;
}
