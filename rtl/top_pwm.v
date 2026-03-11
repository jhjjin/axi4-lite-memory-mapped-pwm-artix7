`timescale 1ns / 1ps

module top_pwm(
    input wire clk,
    input wire rst_n,
    
    // AXI Write Address Channel
    input wire s_axi_awvalid,
    output wire s_axi_awready,
    input wire[3:0] s_axi_awaddr,
    
    // AXI Write Data Channel
    input wire s_axi_wvalid,
    output wire s_axi_wready,
    input wire[31:0] s_axi_wdata,
    
    // AXI Write Response Channel
    output wire s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI Read Address Channel
    input wire s_axi_arvalid,
    output wire s_axi_arready,
    input wire[3:0] s_axi_araddr,
    
    // AXI Read Data Channel
    output wire s_axi_rvalid,
    input wire s_axi_rready,
    output wire[31:0] s_axi_rdata,
    
    output wire pwm_out,
    output wire done
);
    //Interconnet
    wire wr_en_w;
    wire[1:0] addr_w;
    wire[31:0] wr_data_w;
    wire[31:0] rd_data_w;
    
    wire enable_w;
    wire[31:0] period_w;
    wire[31:0] duty_w;
    
    // AXI Slave
    axi_lite_slave u_axi(
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
        
        .wr_en(wr_en_w),
        .addr(addr_w),
        .wr_data(wr_data_w),
        .rd_data(rd_data_w)
 );
    
    
    // Register BLock 
    reg_block u_reg(
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en_w),
        .addr(addr_w),
        .wr_data(wr_data_w),
        .done_in(done),
        .enable_out(enable_w),
        .period_out(period_w),
        .duty_out(duty_w),
        .rd_data(rd_data_w)
    );
    
    pwm_core u_pwm(
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable_w),
        .period(period_w),
        .duty(duty_w),
        .pwm_out(pwm_out),
        .done(done)
    );
endmodule
