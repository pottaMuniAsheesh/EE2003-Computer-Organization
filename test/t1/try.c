#include <stdio.h>

void red(int *);
int main()
{
	int i = 3;
	while(i > 1)
	{
		red(&i);
		printf("%d",i);
	}
	if(i != 1)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}
void red(int *i)
{
	 *i = *i - 1;
}
