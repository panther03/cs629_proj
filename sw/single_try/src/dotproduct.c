#include "../mmio.h"
#include "../bsp.h"

const int c0_v1data[] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
const int c0_v2data[] = {1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0};

void puts(char* string) {
    while (*string != 0) {
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

int main(int a) {
    if (a == 1) { return 1; }
    const char* c0_string = "Core 0: Finished";
    const char* c1_string = "Core 1: Finished";
    const char* c2_string = "Core 2: Finished";
    const char* c3_string = "Core 3: Finished";
    const char* c4_string = "Core 4: Finished";
    int cpuid = *BSP_CPU_ID;
    
    if (cpuid == 0) {
	
	for(int i=1;i<5;i=i+1){
		bsp_put(i, c0_v1data+(multiply(4,i-1)), SCRATCH_START, 4);		//first put the v1 from SCRATCH_START then put the v2 after 4 address.
		bsp_put(i, c0_v2data+(multiply(4,i-1)), SCRATCH_START+4, 4);		
	}

    }
    bsp_sync();
    
    if (cpuid != 0) {							// all the cpus apart from 0 start calculation
	    *(SCRATCH_START+8)=0; 
	    for (int* scratch_ptr = SCRATCH_START; scratch_ptr < SCRATCH_START + 4; scratch_ptr++) {	// results is overwritten to (SCRATCH_START+8)
		    *(SCRATCH_START+8)=*(SCRATCH_START+8)+multiply((* scratch_ptr),(*(scratch_ptr+4)));
	    } 	     
	    bsp_put(0, (SCRATCH_START+8), SCRATCH_START+cpuid, 1);	//bsp_put targets the same core but different address as according to their ID from SCRATCH_START
    }
    
    bsp_sync();								// another sync since we calle bsp_put
    
    
    if (cpuid == 0) {							//CPU0 sums the results
    	*SCRATCH_START=0;	
	for(int i=1;i<5;i=i+1)	*SCRATCH_START=*SCRATCH_START+*(SCRATCH_START+i);
    }

    if (cpuid == 0) {							// CPU0 prints the result
        puts(c0_string);
        for (int i = 0; i < 1000; i++) asm volatile ("");
        putchar(0x30 + *SCRATCH_START);					// print the final result
    } else {
        for (int i = 0; i < 1000; i++) asm volatile ("");
            putchar(0x30 + *(SCRATCH_START+8));				// print the final result
            if(cpuid==1) puts(c1_string);
            else if(cpuid==2) puts(c2_string);
            else if(cpuid==3) puts(c3_string);
            else if(cpuid==4) puts(c4_string);
    }

}
