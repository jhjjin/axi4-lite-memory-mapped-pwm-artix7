`timescale 1ns / 1ps

module tb_top_pwm;

// Clock Genration
reg clk = 0;
reg rst_n;            // Active-low reset 

// Write Address Channel
reg s_axi_awvalid;          // Master asserts when write address is valid  // asserts high(1)
wire s_axi_awready;         // Salve asserts when ready to accept address
reg[3:0] s_axi_awaddr;      // Write address 

//Write Data Channel 
reg s_axi_wvalid;           // Master asserts when wrtie data is valid
wire s_axi_wready;          // Slave ready for write data
reg[31:0] s_axi_wdata;      // Write data (32bit)

// Write Response Channel
wire s_axi_bvalid;          // Slave asserts when write response is ready
reg s_axi_bready;           // Master acknowledges write response

// Read Address Channel
reg s_axi_arvalid;          // Master asserts when read address is valid
wire s_axi_arready;         // Slave ready to accept read address
reg[3:0] s_axi_araddr;      // Read address

// Read Data Channel 
wire s_axi_rvalid;          // Slave asserts when read data is valid
reg s_axi_rready;           // Master acknowledges read data
wire[31:0] s_axi_rdata;     // Read data from salve
 
// DUT Instance
top_pwm dut(
    .clk(clk),
    .rst_n(rst_n),
    
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_awaddr(s_axi_awaddr),
    
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_wdata(s_axi_wdata),
    
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_araddr(s_axi_araddr),
    
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .s_axi_rdata(s_axi_rdata),
    
    .pwm_out(),
    .done()
);
always #5 clk = ~clk;
// AXI Write Task 
task axi_write(input[1:0]addr, input [31:0] data); // Simulate AXI wrtie transaction
begin 
    @(posedge clk);                                // Wait for rising clock edge
    s_axi_awaddr <= {addr, 2'b00};                 // Word Aligned address
    s_axi_awvalid <= 1;                            // Indicate address is valid
    s_axi_wdata <= data;                           // Drive write data
    s_axi_wvalid <= 1;                             // Indicate write data is valid
    
    wait(s_axi_awready && s_axi_wready&s_axi_awready && s_axi_wready);           // Wait for slave to accept address
    
    @(posedge clk);                                // Next clock edge
    s_axi_awvalid <= 0;                            // Deassert address valid
    s_axi_wvalid <=0;                              // Deassert data valid
    
    wait (s_axi_bvalid);                           // Wait until slave asserts response
    s_axi_bready <=1;
    @(posedge clk);
    s_axi_bready <=0;                              // Deassert reponse ready
    
end
endtask

// AXI Read Task
task axi_read(input[1:0] addr, output reg[31:0] data);
begin
    @(posedge clk);
    s_axi_araddr <= {addr, 2'b00};
    s_axi_arvalid <= 1;
    
    wait(s_axi_arready && s_axi_arready);
    
    @(posedge clk);
    s_axi_arvalid <= 0;
    
    wait (s_axi_rvalid);
    data = s_axi_rdata;
    s_axi_rready <=1;
        
    @(posedge clk);
    s_axi_rready <=0;                   // Complete read handshake
    end
endtask

// Test Sequence           
reg[31:0] read_back;
integer i;
integer rand_period;
integer rand_duty;

initial begin
    clk =0; 
    rst_n =0;
    
    s_axi_awvalid =0;
    s_axi_wvalid =0;
    s_axi_bready =0;
    
    s_axi_arvalid =0;
    s_axi_rready =0;
    
    #30;                                    // Hold reset for 30ns
    rst_n =1;                               // Release reset
    
    // Directed Wirte / Read Tests

    axi_write(2'b01, 32'd8);                // Write PERIOD = 8
    @(posedge clk);
    axi_read(2'b01, read_back);             // Read back PERIOD
    
    if(read_back != 32'd8) begin
        $display("READ FAIL: PERIOD expected 8, got %d", read_back);
        $fatal(1);
    end else begin
        $display("READ PASS: PERIOD correct");
    end
    
    //Write DUTY =3
    axi_write(2'b10, 32'd3);                // Write DUTY =3 
    @(posedge clk);
    axi_read(2'b10, read_back);             // Read back DUTY
    
    if(read_back != 32'd3) begin 
        $display("READ FAIL: DUTY expected 3 , got %d", read_back);
        $fatal(1);
   end else begin
        $display("READ PASS: DUTY correct");
   end
  
   // Random Consistency Test
   for (i=0; i< 20; i = i+1) begin
    rand_period = $urandom_range(0,50);
    rand_duty = $urandom_range(0,50);
    
    axi_write(2'b01, rand_period);
    axi_write(2'b10, rand_duty);
    
    axi_read(2'b01, read_back);
    if(read_back != rand_period) begin
        $display("RANDOM FAIL: PERIOD mismatch");
        $fatal(1);
    end
    
    axi_read(2'b10, read_back);
    if(read_back != rand_duty) begin
        $display ("RANDOM FAIL: DUTY mismatch");
        $fatal(1);
    end
  end
  
  $display("ALL AXI READ/WRITE TESTS PASS");
  $finish;
  end
endmodule