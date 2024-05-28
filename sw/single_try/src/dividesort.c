#include "../mmio.h"
#include "../bsp.h"

//const int c0_v1data[] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
//const int c0_v2data[] = {1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0};
const int sort_this[] = {5,8,1,2,2,0,6,9,9,5,4,7,2,1,7,3};
//	  sorted[]={0,1,1,2,2,2,3,4,5,5,6,7,7,8,9,9};	

void swap(int *a,int *b){
	int temp=*a;
	*a=*b;
	*b=temp;
}

void merge(int *a1, int *a2, int *dest, int len){
	int *p1=a1;
	int *p2=a2;
	int *p3=dest;
	
	while((p1<a1+len) &&(p2<a2+len)){
		if(*p1<=*p2){
			*p3=*p1;
			p1++;
		}else{
			*p3=*p2;
			p2++;
		}
		p3++;
	}
	while((p1<a1+len)){
		*p3=*p1;
		p1++;
		p3++;		
	}
	while((p2<a2+len)){

		*p3=*p2;
		p2++;
		p3++;
	}
	
}
int partition(int* p, int start, int end) {
    int x = *(p+end); // threshold
    int j, tmp, i = start - 1;
    for (j = start; j < end; j++) {
        if (*(p+j)< x) {
            i++;
            swap((p+i),(p+j));
        }
    }
    swap((p+(i+1)),(p+end));
    return i + 1;
}
void quick_sort(int* p, int start, int end) {
    if (start < end) {
        int q = partition(p, start, end);
        quick_sort(p, start, q - 1);
        quick_sort(p, q + 1, end);
    }
}     

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
    const char* c5_string = "before sorting: ";
    const char* c6_string = "True";
    const char* c7_string = "False";
    const char* c8_string = "after first merge sorting: ";
    const char* c9_string = "final sorted: ";

    
    int cpuid = *BSP_CPU_ID;

    if (cpuid == 0) {
    	
	for(int i=1;i<5;i=i+1){
		bsp_put(i, sort_this+multiply(4, i-1), SCRATCH_START, 4);		//first put the v1 from SCRATCH_START then put the v2 after 4 address.		
	}
	
    } 
    bsp_sync();  
    
    if (cpuid !=0) {
	
	    for (int i = 0; i < 1000; i++) asm volatile ("");    	    								
	    quick_sort(SCRATCH_START,-1,3);
	    bsp_put(0, SCRATCH_START, SCRATCH_START+multiply(4,(cpuid-1)), 4);	//bsp_put targets the same core but different address as according to their ID from SCRATCH_START
	   
    }
    
    bsp_sync();								 
    
    if (cpuid == 0) {	
    
    	for (int i = 0; i < 1000; i++) asm volatile ("");  
    								
	merge(SCRATCH_START,SCRATCH_START+4,SCRATCH_START+16,4);
	merge(SCRATCH_START+8,SCRATCH_START+12,SCRATCH_START+24,4);	
	merge(SCRATCH_START+16,SCRATCH_START+24,SCRATCH_START+32,8);
	
	puts(c9_string);	
	for(int* scratch_ptr = SCRATCH_START+32; scratch_ptr < SCRATCH_START + 48; scratch_ptr++)	putchar(0x30 + *scratch_ptr);
	
    }	
    else {
        for (int i = 0; i < 1000; i++) asm volatile ("");
            //putchar(0x30 + *(SCRATCH_START+8));				// print the final result
            /*if(cpuid==1) puts(c1_string);
            else if(cpuid==2) puts(c2_string);
            else if(cpuid==3) puts(c3_string);
            else if(cpuid==4) puts(c4_string);*/
    }
    bsp_sync();

}
