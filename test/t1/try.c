#include <stdio.h>

void red(int *);

int main()
{
	int i = 3;
	while(i > 1)
	{
		red(&i);
	}
	if(i != 1)
	{
		return 0;
	}
	else
	{
		return 314;
	}
}
void red(int *i)
{
	 *i = *i - 1;
}
