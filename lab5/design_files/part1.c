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

// Begin part1.s for Lab 7
void clear_screen();
void draw_line(int x0, int y0, int x1, int y1, short int colo);
void plot_pixel(int x, int y, short int line_color);
void swap(int *a, int *b);

volatile int pixel_buffer_start; // global variable

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;

    clear_screen();
    draw_line(0, 0, 150, 150, 0x001F);   // this line is blue
    draw_line(150, 150, 319, 0, 0x07E0); // this line is green
    draw_line(0, 239, 319, 239, 0xF800); // this line is red
    draw_line(319, 0, 0, 239, 0xF81F);   // this line is a pink color
}

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
