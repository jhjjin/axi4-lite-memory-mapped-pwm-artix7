// AXI-Lite 5 Channel AW (Write Address) , W(Write Data), B (Write Response), AR (Read Address), R (Read Data)
// AXI Write Channel FSM 
// Master send addr (AW)-> Master data (W) -> Slave send respond (B)
// AXI Read Channel Addr (Ar) -> data (r)
// AXI Read : Master arvalid =1 -> send addr -> slave arready =1 -> slave rdata -> rvalid = 1 send data -> master rready =1 accept
// Slave : Component that waits for a request from a Master and perfoms the action as commanded
`timescale 1ns / 1ps
module axi_lite_slave(
    input wire clk,
    input wire rst_n,
    
    // Write Address Channel
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    input wire[3:0] s_axi_awaddr,
    
    // Wirete Data Channel
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    input wire[31:0] s_axi_wdata,
    
    // Write Response Channel
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // Read Address Channel
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    input wire[3:0] s_axi_araddr,
    
    // Read Data Channel
    output reg s_axi_rvalid,
    input wire  s_axi_rready,
    output reg[31:0] s_axi_rdata,
    
    //Interface to register block
    output reg wr_en,
    output reg[1:0] addr,
    output reg[31:0] wr_data,
    
    input wire [31:0] rd_data
    );
    // State Encoding , state for AXI Write Read transaction
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;
    localparam RRESP = 2'b11;
    reg [1:0] state;            // Hold state info 
    
    // Finitie State Machine
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin            // Start in safe state
            state <= IDLE;
            // Write Channel 
            s_axi_awready <= 0;
            s_axi_wready <= 0;
            s_axi_bvalid <= 0;
            
            // Read channel reset 
            s_axi_arready <=0;
            s_axi_rvalid <=0;
            s_axi_rdata <=0;
            wr_en <= 0;            
            addr <= 0;
            wr_data <=0;
        end
        else begin 
            wr_en <= 0;                  // only pulse for one clock cycle 
            
            case (state)
                IDLE: begin              // Ready to allow a handshake (send data)
                    s_axi_awready <=1;
                    s_axi_wready <= 1;                     
                    s_axi_arready <= 1;
                    s_axi_rvalid <=0; 
                    s_axi_bvalid <= 0;
                    // Single Outstanding Transaction
                    if(s_axi_awvalid&& s_axi_wvalid) begin  // Check AXI addr, data channel are independent assume both arrive together
                        addr <= s_axi_awaddr[3:2];  // AXI addresses are byte-base 0x00, 0x04, 0x08..
                        wr_data <= s_axi_wdata;
                        wr_en <= 1;
                        
                        s_axi_awready <= 0;
                        s_axi_wready <= 0;
                        state <= WRITE;      // After write, send a write response
                     end
                     
                     // Read 
                     else if (s_axi_arvalid) begin
                        
                        addr <= s_axi_araddr[3:2];  // read addr latch , hold the memory address to ensure stable data
                        s_axi_arready <=0;
                        state <= READ;
                     end
                 end
                 
                READ: begin
                    s_axi_rdata <= rd_data;
                    s_axi_rvalid <=1;
                    state <= RRESP;
                    
                  end  
                WRITE: begin
                    s_axi_bvalid <=1;
                    if(s_axi_bready)begin
                        s_axi_bvalid <=0;
                        state <= IDLE;
                    end
                end
                RRESP: begin    
                    if(s_axi_rready) begin
                        s_axi_rvalid <=0;
                        state <= IDLE; 
                     end
                  end
               endcase
             end   
        end         
   
endmodule
