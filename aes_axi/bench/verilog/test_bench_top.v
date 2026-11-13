/////////////////////////////////////////////////////////////////////
////                                                             ////
////  AES Test Bench                                             ////
////                                                             ////
////                                                             ////
////  Author: Rudolf Usselmann                                   ////
////          rudi@asics.ws                                      ////
////                                                             ////
////                                                             ////
////  Downloaded from: http://www.opencores.org/cores/aes_core/  ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2000-2002 Rudolf Usselmann                    ////
////                         www.asics.ws                        ////
////                         rudi@asics.ws                       ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: test_bench_top.v,v 1.2 2002-11-12 16:10:12 rudi Exp $
//
//  $Date: 2002-11-12 16:10:12 $
//  $Revision: 1.2 $
//  $Author: rudi $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.1.1.1  2002/11/09 11:22:56  rudi
//               Initial Checkin
//
//
//
//
//
//

`include "timescale.v"

module test;

reg		clk;
reg		rst;

reg	[383:0]	tv[3:0];	// Test vectors
wire	[383:0]	tmp;
reg		kld;
wire	[127:0]	key, plain, ciph;
wire	[127:0]	text_in;
wire	[127:0]	text_out;
wire	[127:0]	text_out2;
reg	[127:0]	text_exp;
wire		done, done2;
integer		n, error_cnt;

initial
   begin
	$display("\n\n");
	$display("*****************************************************");
	$display("* AES Test bench ...");
	$display("*****************************************************");
	$display("\n");

	kld = 0;
	clk = 0;
	rst = 0;
	error_cnt = 0;
	repeat(4)	@(posedge clk);
	rst = 1;
	repeat(20)	@(posedge clk);

	$display("");
	$display("");
	$display("Started 4-vector AES test ...");

tv[0]= 384'h000000000000000000000000000000000000000000000000000000000000000066e94bd4ef8a2c3b884cfa59ca342b2e;
tv[1]= 384'h000102030405060708090a0b0c0d0e0f00112233445566778899aabbccddeeff69c4e0d86a7b0430d8cdb78070b4c55a;
tv[2]= 384'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbcbf217cb280cf30b2517052193ab979;
tv[3]= 384'h00000000000000000000000000000000ffffffffffffffffffffffffffffffff3f5b8cc9ea855a0afa7347d23e8d664e;


for(n=0;n<4;n=n+1)
   begin
	@(posedge clk);
	#1;
	kld = 1;
	@(posedge clk);
	#1;
	kld = 0;
	@(posedge clk);

	while(!done)	@(posedge clk);

	//$display("INFO: (a) Vector %0d: xpected %x, Got %x %t", n, ciph, text_out, $time);

	if(text_out != ciph | (|text_out)==1'bx)
	   begin
		$display("ERROR: (a) Vector %0d mismatch. Expected %x, Got %x",
			n, ciph, text_out);
		error_cnt = error_cnt + 1;
	   end


	while(!done2)	@(posedge clk);

	//$display("INFO: (b) Vector %0d: xpected %x, Got %x", n, plain, text_out2);

	if(text_out2 != plain | (|text_out2)==1'bx)
	   begin
		$display("ERROR: (b) Vector %0d mismatch. Expected %x, Got %x",
			n, plain, text_out2);
		error_cnt = error_cnt + 1;
	   end

	@(posedge clk);
	#1;
   end


	$display("");
	$display("");
	$display("Test Done. Found %0d Errors.", error_cnt);
	$display("");
	$display("");
	repeat(10)	@(posedge clk);
	$finish;
end

assign tmp = tv[n];
assign key     = kld ? tmp[383:256] : 128'h0;
assign text_in = kld ? tmp[255:128] : 128'h0;
assign plain   = tmp[255:128];
assign ciph    = tmp[127:0];

always #5 clk = ~clk;

aes_cipher_top u0(
	.clk(		clk		),
	.rst(		rst		),
	.ld(		kld		),
	.done(		done		),
	.key(		key		),
	.text_in(	text_in		),
	.text_out(	text_out	)
	);

aes_inv_cipher_top u1(
	.clk(		clk		),
	.rst(		rst		),
	.kld(		kld		),
	.ld(		done		),
	.done(		done2		),
	.key(		key		),
	.text_in(	text_out	),
	.text_out(	text_out2	)
	);


initial
begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars("+all");
    $fsdbDumpSVA;
    $fsdbDumpMDA;
end

endmodule

