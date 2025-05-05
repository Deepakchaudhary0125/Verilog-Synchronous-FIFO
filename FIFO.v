module fifo_sync 
#(parameter FIFO_DEPTH = 8,
parameter DATA_WIDTH = 32)
(
     input clk, cs, reset,
     input[7:0] data_in, 
     output reg [DATA_WIDTH-1:0]data_out,
     input read_en, write_en,
     output empty, full
);
 
localparam  add_width=$clog2(FIFO_DEPTH);
//Array declaraiton 
reg [DATA_WIDTH-1:0] fifo [FIFO_DEPTH-1:0];

// Pointers
reg[add_width-1:0] write_pointer;
reg[add_width-1:0] read_pointer;

//write 
always @(posedge clk or posedge reset) begin
     if(reset) 
          write_pointer<=0;
     else if(cs && write_en && !full) begin
          fifo[write_pointer]<=data_in;
          write_pointer<=write_pointer + 1'b1;
     end
end

//Read
always @(posedge clk or posedge reset) begin
     if(reset) 
          read_pointer<=0;
     else if(cs && read_en && !empty) begin
          data_out<=fifo[read_pointer];
         read_pointer<=read_pointer + 1'b1;
     end
end

// declare end logic
assign empty=(read_pointer==write_pointer);
assign full = ((write_pointer + 1'b1) == read_pointer);


endmodule

`timescale 1ps/1ps;

module fifo_tb;
parameter FIFO_DEPTH = 8;
parameter DATA_WIDTH = 32;
     reg clk;
     reg reset;
     reg[7:0] data_in;
     reg read_en;
     reg cs;
     reg write_en;
     wire  [DATA_WIDTH-1:0] data_out;
     wire empty;
     wire full;

     integer i;

     fifo_sync #(.FIFO_DEPTH(FIFO_DEPTH),.DATA_WIDTH(DATA_WIDTH)) uut (
          .clk(clk),
          .reset(reset),
          .data_in(data_in),
          .read_en(read_en),
          .cs(cs),
          .write_en(write_en),
          .data_out(data_out),
          .empty(empty),
          .full(full)
     );
     
    always begin #5 clk=~clk;
    end
     
     task write_data(input[DATA_WIDTH-1:0] d_in);
          begin
            @(posedge clk ) ;
                  cs=1; write_en=1 ;
                  data_in = d_in;
                  @(posedge clk);
                  write_en=0; cs=1;
               end
     endtask
     
     task read_data();
     begin
          @(posedge clk);
          cs=1; read_en=1;
          @(posedge clk);
          cs=1; read_en=0; 
     end
     endtask

     initial begin
          #1;
          reset=1; write_en=0; read_en=0;
          @(posedge clk)
          reset=0;
          $display($time,"\n SCENERIO 1");
          write_data(1);
          write_data(10);
          write_data(100);
          read_data();
          read_data();
          read_data();

          $display($time,"\n SCENERIO 2");
          for(integer i=0; i<FIFO_DEPTH; i=i+1) begin
               write_data(2**i);
               read_data();
          end
          $display($time,"\n SCENERIO 3");
          for(integer i=0; i<FIFO_DEPTH; i=i+1) begin
               write_data(2**i);
               
          end

          for(integer i=0; i<FIFO_DEPTH; i=i+1) begin
               read_data();
               
          end
     end
     initial begin
          $dumpfile("fifo_tb.vcd");
     $dumpvars;
     end
endmodule