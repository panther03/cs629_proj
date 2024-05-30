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
	int num_slave = 8;
	int size_each = 16;

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

	int cpuid = *BSP_CPU_ID;

	if (cpuid == 0)
	{

		for (int i = 1; i <= num_slave; i = i + 1)
		{
			bsp_put(i, sort_this + multiply(size_each, i - 1), SCRATCH_START, size_each); // puts equal amoun of data to each proc. from SCRATCH_START
		}
	}
	bsp_sync();

	if (cpuid != 0)
	{

		for (int i = 0; i < 1000; i++)
			asm volatile("");
		quick_sort(SCRATCH_START, -1, size_each - 1);											// sorts the subblocks
		bsp_put(0, SCRATCH_START, SCRATCH_START + multiply(size_each, (cpuid - 1)), size_each); // takes sorted subblocks and put it to core0 from SCRATCH_START with a different address according ID
	}

	bsp_sync();

	if (cpuid == 0)
	{

		for (int i = 0; i < 1000; i++)
			asm volatile("");

		int offset = multiply(size_each, num_slave);
		int count = 0;
		int number = num_slave;
		int temp_offset = offset;
		int temp_size = size_each;
		int mult_fac = 1;

		while (number > 1)
		{ // iteratively merging the sorted arrays and overwriting it. Memory space is just 2N where N is the number of elements we sort.
			count = 0;
			int diff = offset - temp_offset;
			while (count < number)
			{
				int x = multiply(temp_size, count);
				merge(SCRATCH_START + diff + x, SCRATCH_START + diff + x + temp_size, SCRATCH_START + temp_offset, temp_size);
				count = count + 2;
				temp_offset = temp_offset + (temp_size << 1);
			}

			if (mult_fac == 1)
			{
				mult_fac = -1;
				temp_offset = 0;
			}
			else
			{
				mult_fac = 1;
				temp_offset = offset;
			}
			temp_size = (temp_size << 1);
			number = number >> 1;
		}

		puts(c9_string);
		if (mult_fac == 1)
			for (int *scratch_ptr = SCRATCH_START; scratch_ptr < SCRATCH_START + offset; scratch_ptr++)
				putchar(0x30 + *scratch_ptr);
		else
			for (int *scratch_ptr = SCRATCH_START + offset; scratch_ptr < SCRATCH_START + multiply(offset, 2); scratch_ptr++)
				putchar(0x30 + *scratch_ptr);
	}

	else
	{
		for (int i = 0; i < 1000; i++)
			asm volatile("");
		if (cpuid == 1)
			puts(c1_string);
		else if (cpuid == 2)
			puts(c2_string);
		else if (cpuid == 3)
			puts(c3_string);
		else if (cpuid == 4)
			puts(c4_string);
	}
}