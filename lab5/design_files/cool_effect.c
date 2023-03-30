/* This files provides address values that exist in the system */

#define SDRAM_BASE            0xC0000000
#define FPGA_ONCHIP_BASE      0xC8000000
#define FPGA_CHAR_BASE        0xC9000000

/* Cyclone V FPGA devices */
#define LEDR_BASE             0xFF200000
#define HEX3_HEX0_BASE        0xFF200020
#define HEX5_HEX4_BASE        0xFF200030
#define SW_BASE               0xFF200040
#define KEY_BASE              0xFF200050
#define TIMER_BASE            0xFF202000
#define PIXEL_BUF_CTRL_BASE   0xFF203020
#define CHAR_BUF_CTRL_BASE    0xFF203030

/* VGA colors */
#define WHITE 0xFFFF
#define YELLOW 0xFFE0
#define RED 0xF800
#define GREEN 0x07E0
#define BLUE 0x001F
#define CYAN 0x07FF
#define MAGENTA 0xF81F
#define GREY 0xC618
#define PINK 0xFC18
#define ORANGE 0xFC00

#define ABS(x) (((x) > 0) ? (x) : -(x))

/* Screen size. */
#define RESOLUTION_X 320
#define RESOLUTION_Y 240

/* Constants for animation */
#define BOX_LEN 2
#define NUM_BOXES 8

#define FALSE 0
#define TRUE 1

#include <stdlib.h>
#include <stdio.h>
#include <time.h>

// Begin part3.c code for Lab 7
void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, short int colo);
void plot_pixel(int x, int y, short int line_color);
void swap(int *a, int *b);
void wait_for_vsync();

volatile int pixel_buffer_start; // global variable

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    // declare other variables(not shown)
    // initialize location and direction of rectangles (shown)
	srand(time(NULL));
	int x_box[8], y_box[8], dx_box[8], dy_box[8];
	short int color[8];
	
	for (int i = 0; i < 8; i++){
		dx_box[i] = rand()%2*2-1;
		dy_box[i] = rand()%2*2-1;
		
		x_box[i] = rand()%(RESOLUTION_X - 1);
		y_box[i] = rand()%(RESOLUTION_Y - 1);
		
		color[i] = rand()%(0xFFFF);
	}	
	
	int old_x[8], old_y[8];
	
	for (int i = 0; i < 8; i++){
		old_x[i] = x_box[i];
		old_y[i] = y_box[i];
	}

    /* set front pixel buffer to start of FPGA On-chip memory */
    *(pixel_ctrl_ptr + 1) = 0xC8000000; // first store the address in the 
                                        // back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait_for_vsync();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer
    /* set back pixel buffer to start of SDRAM memory */
    *(pixel_ctrl_ptr + 1) = 0xC0000000;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer
    clear_screen(); // pixel_buffer_start points to the pixel buffer

    while (1){
        /* Erase any boxes and lines that were drawn in the last iteration */
        for (int i = 0; i < 8; i++){
			for (int x = 0; x < 4; x++){
				for (int y = 0; y < 4; y++){
					plot_pixel(old_x[i] + x, old_y[i] + y, 0x0000);
				}
			}
			draw_line(old_x[i], old_y[i], old_x[(i+1)%8], old_y[(i+1)%8], 0x0000);
		}
		
        // code for drawing the boxes and lines (not shown)
        // code for updating the locations of boxes (not shown)
		for (int i = 0; i < 8; i++){
			for (int x = 0; x < 4; x++){
				for (int y = 0; y < 4; y++){
					plot_pixel(x_box[i] + x, y_box[i] + y, color[i]);
				}
			}
			
			draw_line(x_box[i] + 2, y_box[i] + 2, x_box[(i+1)%8] + 2, y_box[(i+1)%8] + 2, color[i]);
			
			old_x[i] = x_box[i];
			old_y[i] = y_box[i];
			
			x_box[i] += dx_box[i];
			if (x_box[i] < 0){
				x_box[i] = 0;
				dx_box[i] = -dx_box[i];
			}else if (x_box[i] > RESOLUTION_X - 4){
				x_box[i] = RESOLUTION_X - 4;
				dx_box[i] = -dx_box[i];
			}
			
			y_box[i] += dy_box[i];
			if (y_box[i] < 0){
				y_box[i] = 0;
				dy_box[i] = -dy_box[i];
			}else if (y_box[i] > RESOLUTION_Y - 4){
				y_box[i] = RESOLUTION_Y - 4;
				dy_box[i] = -dy_box[i];
			}
		}
		
        wait_for_vsync(); // swap front and back buffers on VGA vertical sync
        pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
    }
}

// code for subroutines (shown)

void swap(int *a, int *b){
	int temp = *a;
	*a = *b;
	*b = temp;
}

// code shown for clear_screen() and draw_line() subroutines
void clear_screen(){
	for (int x = 0; x < 320; x++)
		for (int y = 0; y < 240; y++)
			plot_pixel(x, y, 0x0000);
}

void draw_line(int x0, int y0, int x1, int y1, short int colo){
	int is_steep = (ABS(y1 - y0) > ABS(x1 - x0))?TRUE:FALSE;
	
	if (is_steep == TRUE){
		swap(&x0, &y0);
		swap(&x1, &y1);
	}
	
	if (x0 > x1){
		swap(&x0, &x1);
		swap(&y0, &y1);
	}
	
	int dx = x1 - x0;
	int	dy = ABS(y1 - y0);
	int error = -(dx/2);
	int y = y0;
	int y_step = (y0 < y1)?1:-1;
	
	for (int x = x0; x < x1; x++){
		if (is_steep == TRUE)
			plot_pixel(y, x, colo);
		else 
			plot_pixel(x, y, colo);
		
		error += dy;
		
		if (error > 0){
			y += y_step;
			error -= dx;
		}
	}
}

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

void wait_for_vsync(){
	volatile int* pixel_ctrl_ptr = (int *)0xFF203020;
	register int status;
	
	*pixel_ctrl_ptr = 1;
	
	status = *(pixel_ctrl_ptr + 3);
	while ((status & 0x01) != 0){
		status = *(pixel_ctrl_ptr + 3);
	}
}
