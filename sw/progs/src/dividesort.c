#include "../mmio.h"
#include "../bsp.h"

const int sort_this[] = {5, 8, 1, 2, 2, 0, 6, 9, 9, 5, 4, 7, 2, 1, 7, 3, 1, 2, 1, 4, 4, 7, 5, 5, 5, 3, 8, 9, 1, 3, 3, 7, 5, 8, 1, 2, 2, 0, 6, 9, 9, 5, 4, 7, 2, 1, 7, 3, 1, 2, 1, 4, 4, 7, 5, 5, 5, 3, 8, 9, 1, 3, 3, 7, 5, 8, 1, 2, 2, 0, 6, 9, 9, 5, 4, 7, 2, 1,
						 7, 3, 1, 2, 1, 4, 4, 7, 5, 5, 5, 3, 8, 9, 1, 3, 3, 7, 5, 8, 1, 2, 2, 0, 6, 9, 9, 5, 4, 7, 2, 1, 7, 3, 1, 2, 1, 4, 4, 7, 5, 5, 5, 3, 8, 9, 1, 3, 3, 7};

void swap(int *a, int *b)
{
	int temp = *a;
	*a = *b;
	*b = temp;
}

void merge(int *a1, int *a2, int *dest, int len)
{ // merge any two sorted arrays and write it to destination
	int *p1 = a1;
	int *p2 = a2;
	int *p3 = dest;

	while ((p1 < a1 + len) && (p2 < a2 + len))
	{
		if (*p1 <= *p2)
		{
			*p3 = *p1;
			p1++;
		}
		else
		{
			*p3 = *p2;
			p2++;
		}
		p3++;
	}
	while ((p1 < a1 + len))
	{
		*p3 = *p1;
		p1++;
		p3++;
	}
	while ((p2 < a2 + len))
	{

		*p3 = *p2;
		p2++;
		p3++;
	}
}
int partition(int *p, int start, int end)
{
	int x = *(p + end); // threshold
	int j, tmp, i = start - 1;
	for (j = start; j < end; j++)
	{
		if (*(p + j) < x)
		{ // quicksort algorithm that will be running on the slave cores
			i++;
			swap((p + i), (p + j));
		}
	}
	swap((p + (i + 1)), (p + end));
	return i + 1;
}
void quick_sort(int *p, int start, int end)
{
	if (start < end)
	{
		int q = partition(p, start, end);
		quick_sort(p, start, q - 1);
		quick_sort(p, q + 1, end);
	}
}

void puts(char *string)
{
	while (*string != 0)
	{
		putchar(*string);
		string++;
	}
}
int multiply(int x, int y)
{

	int ret = 0;
	for (int i = 0; i < 32; i++)
	{
		if (((y >> i) & 1) == 1)
		{
			ret += (x << i);
		}
	}
	return ret;
}

int main(int a)
{

	int size_of_array = 128; // parameters that can be configured

	if (a == 1)
	{
		return 1;
	}
	const char *c0_string = "Core 0: Finished";
	const char *c1_string = "Core 1: Finished";
	const char *c2_string = "Core 2: Finished";
	const char *c3_string = "Core 3: Finished";
	const char *c4_string = "Core 4: Finished";
	const char *c9_string = "final sorted: ";

	quick_sort(sort_this, 0, size_of_array);
	puts(c9_string);
	for (int *p = sort_this; p < sort_this + size_of_array; p++)
		putchar(0x30 + *p);
}
