`timescale 1ns / 1ps

module reg_block(
    input wire clk,                     // clock
    input wire rst_n,                   // Reset active low 
    input wire wr_en,                   // Write enable (signal of CPU)
    input wire[1:0] addr,               // Select which register 
    input wire[31:0] wr_data,           // Data that use for CPU 
    input wire done_in,                 // done signal from PWM 
    output reg enable_out,              // connect to PWM enable
    output reg [31:0] period_out,       // connect to PWM period
    output reg[31:0] duty_out,           // connect to PWM duty 
    output reg [31:0] rd_data
    );
        
    reg status_reg;                     // Status register (Save done)
    
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin        // When reset, reset all registers
            enable_out <= 1'b0;
            period_out <= 32'd0;
            duty_out <= 32'd0;
            status_reg <= 1'b0;
        end
        else begin              
            //Write the operation
            if(wr_en) begin
                //Write 
                case(addr)
                    2'b00: enable_out <= wr_data[0]; //CTRL register
                    2'b01: period_out <= wr_data;    // Period register  
                    2'b10: duty_out <= wr_data;      // DUTY register
                    default: ;
                   endcase
                 end
                 if(done_in)         // When PWM send done signal, status update 
                    status_reg <= 1'b1;
                 end
              end   
                 // READ posedge to rd_data updated  
                 always@(*) begin             
                 case(addr)
                    2'b00: rd_data = {31'd0, enable_out};
                    2'b01: rd_data = period_out;
                    2'b10: rd_data = duty_out;
                    2'b11: rd_data = {31'd0, status_reg};
                    default: rd_data = 32'd0;
                 endcase
      
   end
   
endmodule
