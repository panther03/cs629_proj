#include "../mmio.h"
#include "../bsp.h"
 
const int c0_v1data[] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
const int c0_v2data[] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};

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

void puts(char* string) {
    while (*string != 0) {
        putchar(*string);
        string++;
    }
}

void putint(int a) {
    int lut[16] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
    for (int i = 1; i < 9; i++) {
        putchar((lut[0xF & (a >> (32-(i<<2)))]));
    }
    putchar('\n');
}

int main(int a) {
    //if (a == 1) { return 1; }
    const char* c0_string = "Core 0: Finished\nResult: ";
    const char* c1_string = "Core 1: Finished";
    const char* c2_string = "Core 2: Finished";
    const char* c3_string = "Core 3: Finished";
    const char* c4_string = "Core 4: Finished";
    int cpuid = *BSP_CPU_ID;
    
    if (cpuid == 0) {
	
	for(int i=1;i<9;i=i+1){
		bsp_put(i, c0_v1data + ((i-1) << 1), SCRATCH_START, 2);		//first put the v1 from SCRATCH_START then put the v2 after 4 address.
		bsp_put(i, c0_v2data + ((i-1) << 1), SCRATCH_START+2, 2);		
	}
    //bsp_dump(64);
    }
    bsp_sync();
    //for (int i = 0; i < 1000; i++) asm volatile ("");
    //return;
    int sum = 0;
    if (cpuid != 0) {							// all the cpus apart from 0 start calculation
	    for (volatile int* scratch_ptr = SCRATCH_START; scratch_ptr < SCRATCH_START + 2; scratch_ptr++) {	// results is overwritten to (SCRATCH_START+8)
		    sum += multiply((* scratch_ptr),(*(scratch_ptr+2)));
	    } 	     
	    bsp_put(0, &sum, SCRATCH_START+cpuid, 1);	//bsp_put targets the same core but different address as according to their ID from SCRATCH_START
    }
    
    bsp_sync();								// another sync since we calle bsp_put
    
    if (cpuid == 0) {							//CPU0 sums the results
	    for(int i=1;i<9;i=i+1)	sum += *(SCRATCH_START+i);
    }
    
    if (cpuid == 0) {
        puts(c0_string);
        for (int i = 0; i < 1000; i++) asm volatile ("");
        putint(sum);					// print the final result, for CPU0 this is the whole sum
    } else {
        if(cpuid==1) puts(c1_string);
        else if(cpuid==2) puts(c2_string);
        else if(cpuid==3) puts(c3_string);
        else if(cpuid==4) puts(c4_string);
    }

}