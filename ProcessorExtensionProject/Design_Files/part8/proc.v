module proc(DIN, Resetn, Clock, Run, DOUT, ADDR, W);
    input [15:0] DIN;
    input Resetn, Clock, Run;
    output wire [15:0] DOUT;
    output wire [15:0] ADDR;
    output wire W;

    wire [0:7] R_in; // r0, ..., r7 register enables
    reg rX_in, IR_in, ADDR_in, Done, DOUT_in, A_in, G_in, AddSub, ALU_and, do_shift, F_in;
    reg [2:0] Tstep_Q, Tstep_D;
    reg [15:0] BusWires;
    reg [3:0] Sel; // BusWires selector
    reg [15:0] Sum;
	reg Carry;			// carry bit
	 
    wire [2:0] III, rX, rY; // instruction opcode and register operands
    wire [15:0] r0, r1, r2, r3, r4, r5, r6, pc, A;
    wire [15:0] G;
    wire [15:0] IR;
    reg pc_incr;    // used to increment the pc
    reg pc_in;      // used to load the pc
    reg sp_incr;    // used to increment
    reg sp_dec;     // used to decrement the sp
    reg sp_in;      // used to load the sp
    reg lr_in;      // used to load the lr
    reg W_D;        // used for write signal
    wire Imm;
	wire [2:0] condition;   // to read condition codes
	wire z, n, c;
	wire z_alu, n_alu, c_alu;
	reg [2:0] F;    // register F

    wire shift_flag;
    wire [1:0] shift_type;
    wire Imm_shift;
    wire [16:0] shift_data_out;
   
    assign III = IR[15:13];
    assign Imm = IR[12];
    assign rX = IR[11:9];
    assign rY = IR[2:0];

	assign c_alu = Carry;			// carry bit of ALU
	assign n_alu = Sum[15];			// MSB
	assign z_alu = ~|Sum[15:0];		// nor gate 
	assign condition = IR[11:9];    //XXX 

    assign shift_flag = IR[8];
    assign shift_type = IR[6:5];
    assign Imm_shift = IR[7];

	 
	always @(posedge Clock) begin
	    if (F_in) 
			F <= {c_alu, n_alu, z_alu};			// contaenate and store into 
	end 

	// set flags
	assign z = F[0];
	assign n = F[1];
	assign c = F[2];
	 
    dec3to8 decX (rX_in, rX, R_in); // produce r0 - r7 register enables

    parameter T0 = 3'b000, T1 = 3'b001, T2 = 3'b010, T3 = 3'b011, T4 = 3'b100, T5 = 3'b101;

    // Control FSM state table
    always @(Tstep_Q, Run, Done)
        case (Tstep_Q)
            T0: // instruction fetch
                if (~Run) Tstep_D = T0;
                else Tstep_D = T1;
            T1: // wait cycle for synchronous memory
                Tstep_D = T2;
            T2: // this time step stores the instruction word in IR
                Tstep_D = T3;
            T3: if (Done) Tstep_D = T0;
                else Tstep_D = T4;
            T4: if (Done) Tstep_D = T0;
                else Tstep_D = T5;
            T5: // instructions end after this time step
                Tstep_D = T0;
            default: Tstep_D = 3'bxxx;
        endcase

    /* OPCODE format: III M XXX DDDDDDDDD, where 
    *     III = instruction, M = Immediate, XXX = rX. If M = 0, DDDDDDDDD = 000000YYY = rY
    *     If M = 1, DDDDDDDDD = #D is the immediate operand 
    *
    *  III M  Instruction       Description
    *  --- -  -----------       -----------
    *  000 0: mv   rX,rY    rX <- rY
    *  000 1: mv   rX,#D    rX <- D (sign extended)
    *  001 1: mvt  rX,#D    rX <- D << 8
    *  010 0: add  rX,rY    rX <- rX + rY
    *  010 1: add  rX,#D    rX <- rX + D
    *  011 0: sub  rX,rY    rX <- rX - rY
    *  011 1: sub  rX,#D    rX <- rX - D
    *  100 0: ld   rX,[rY]  rX <- [rY]
    *  101 0: st   rX,[rY]  [rY] <- rX
    *  100 1: pop  rX       rX ← [sp], sp ← sp + 1
    *  101 1: push rX       sp ← sp − 1, [sp] ← rX
    *  110 0: and  rX,rY    rX <- rX & rY
    *  110 1: and  rX,#D    rX <- rX & D 
    *  111 0: cmp  rX,rY    performs rX − rY, sets flags 
    *  111 1: cmp  rX,#D    performs rX − D, sets flags */
    parameter mv = 3'b000, mvt = 3'b001, add = 3'b010, sub = 3'b011, ld = 3'b100, st = 3'b101,
	     and_ = 3'b110, b_xxx = 3'b001, push = 3'b101, cmp = 3'b111, shift = 3'b111;
    // selectors for the BusWires multiplexer
    parameter _R0 = 4'b0000, _R1 = 4'b0001, _R2 = 4'b0010, _R3 = 4'b0011, _R4 = 4'b0100,
        _R5 = 4'b0101, _R6 = 4'b0110, _PC = 4'b0111, _G = 4'b1000, 
        _IR8_IR8_0 /* signed-extended immediate data */ = 4'b1001, 
        _IR7_0_0 /* immediate data << 8 */ = 4'b1010,
        _DIN /* data-in from memory */ = 4'b1011,
        _IR4 = 4'b1100;
	
	// conditional branches codes  
	parameter none = 3'b000, eq = 3'b001, ne = 3'b010, cc = 3'b011, cs = 3'b100, pl = 3'b101, 
			mi = 3'b110, bl = 3'b111;
			  
    // Control FSM outputs
    always @(*) begin
        // default values for control signals
        rX_in = 1'b0; A_in = 1'b0; G_in = 1'b0; IR_in = 1'b0; DOUT_in = 1'b0; ADDR_in = 1'b0; 
        Sel = 4'bxxxx; AddSub = 1'b0; ALU_and = 1'b0; W_D = 1'b0; Done = 1'b0; F_in = 1'b0;
        pc_in = R_in[7] /* default pc enable */; pc_incr = 1'b0;
        sp_in = R_in[5] /* default sp enable*/; sp_incr = 1'b0; sp_dec = 1'b0;
        lr_in = 1'b0;
        do_shift = 1'b0;

        case (Tstep_Q)
            T0: begin // fetch the instruction
                Sel = _PC;  // put pc onto the internal bus
                ADDR_in = 1'b1;
                pc_incr = Run; // to increment pc
            end
            T1: // wait cycle for synchronous memory
                ;
            T2: // store instruction on DIN in IR 
                IR_in = 1'b1;
            T3: // define signals in T3
                case (III)
                    mv: begin
                        if (!Imm) Sel = rY;          // mv rX, rY
                        else Sel = _IR8_IR8_0;       // mv rX, #D
                        rX_in = 1'b1;                // enable the rX register
                        Done = 1'b1;
                    end
                    mvt: begin
                        if (Imm) begin
							Sel = _IR7_0_0;
							rX_in = 1'b1;
							Done = 1'b1;
						end else begin      //Imm = 0
							Sel = _PC;
							A_in = 1'b1;
							
							case (condition)
								eq: begin	// done if condition of z = 1 not met
									if (z == 1'b0) Done = 1'b1;
								end
										
								ne: begin	// done if condition of z = 0 not met
									if (z == 1'b1) Done = 1'b1;
								end
										
								cs: begin	// done if condition of c = 1 not met
									if (c == 1'b0) Done = 1'b1;
								end
										
								cc: begin	// done if condition of c = 0 not met
									if (c == 1'b1) Done = 1'b1;
								end
								
								mi: begin	// done if condition of n = 1 not met
									if (n == 1'b0) Done = 1'b1;
								end
										
								pl: begin	// done if condition of n = 0 not met
									if (n == 1'b1) Done = 1'b1;
								end
                                bl: begin
                                    lr_in = 1'b1;
                                end
							endcase
						end
                    end
                    
					add, sub, and_, cmp: begin
                        Sel = rX;
                        A_in = 1'b1;	
                    end

                    ld: begin   // ld or pop
                        Sel = rY;
                        ADDR_in = 1'b1;

                        if (Imm)    // one extra control signal for pop
                            sp_incr = 1'b1;
                    end
                    
                    st: begin   // st or push
                        if (Imm == 1'b0) begin  // this is a store instruction
                            Sel = rY;
                            ADDR_in = 1'b1;
                        end else                // this is a push instruction
                            sp_dec = 1'b1;
                    end
			  
                    default: ;
                endcase
            T4: // define signals T2
                case (III)
                    add: begin
                        if (Imm)
                            Sel = _IR8_IR8_0;
                        else
                            Sel = rY; 
                        
                        G_in = 1'b1;
						F_in = 1'b1;						// F_in is only high in add/sub
                    end

                    sub: begin
                        if (Imm)
                            Sel = _IR8_IR8_0;
                        else
                            Sel = rY; 
                            
                        G_in = 1'b1;
						F_in = 1'b1;						// F_in is only high in add/sub
                        AddSub = 1'b1;
                    end

                    and_: begin
                        if (Imm)
                            Sel = _IR8_IR8_0;
                        else
                            Sel = rY; 
                        
                        G_in = 1'b1;
                        ALU_and = 1'b1;
                    end

                    ld: // wait cycle for synchronous memory
                        ;
                    st: begin
                        if (Imm == 1'b0) begin  // this is a store instruction
                            Sel = rX;
                            DOUT_in = 1'b1;
                            W_D = 1'b1;
                            Done = 1'b1;
                        end else begin          // this is a push instruction
                            Sel = rY;
                            ADDR_in = 1'b1;
                        end
                    end
						  
					b_xxx: begin // bxxx = mvt -> can use either paremeter because mvt is done in T3
						Sel = _IR8_IR8_0;
						G_in = 1'b1;
					end

                    cmp: begin
                        if (Imm) begin
                            Sel = _IR8_IR8_0;
                            AddSub = 1'b1; 
                            Done = 1'b1;
                        end
                        else
                            if (shift_flag) begin
                                if (Imm_shift)
                                    Sel = _IR4;
                                else
                                    Sel = rY;

                                do_shift = 1'b1;
                                G_in = 1'b1;
                            end else begin
                                Sel = rY;
                                AddSub = 1'b1; 
                                Done = 1'b1;
                            end

                        F_in = 1'b1;
                    end		
                    default: ; 
                endcase
            T5: // define T3
                case (III)
                    add, sub, and_: begin
                        Sel = _G;
                        rX_in = 1'b1;
                        Done = 1'b1;
                    end

                    ld: begin          // ld and pop behave exactly the same in T5
                        Sel = _DIN;
                        rX_in = 1'b1;
                        Done = 1'b1;
                    end
                    
                    push: begin          // Only the push instruction will get this far
                        Sel = rX;
                        DOUT_in = 1'b1;
                        W_D = 1'b1;
                        Done = 1'b1;
                    end
						  
					b_xxx: begin
						Sel = _G;
						pc_in = 1'b1;
						Done = 1'b1;
					end	  

                    shift: begin        // Only the shift instructions will get this far
                        Sel = _G;
                        rX_in = 1'b1;
                        Done = 1'b1;
                    end  
                    default: ;
                endcase
            default: ;
        endcase
    end   
   
    // Control FSM flip-flops
    always @(posedge Clock)
        if (!Resetn)
            Tstep_Q <= T0;
        else
            Tstep_Q <= Tstep_D;   
   
    regn reg_0 (BusWires, Resetn, R_in[0], Clock, r0);
    regn reg_1 (BusWires, Resetn, R_in[1], Clock, r1);
    regn reg_2 (BusWires, Resetn, R_in[2], Clock, r2);
    regn reg_3 (BusWires, Resetn, R_in[3], Clock, r3);
    regn reg_4 (BusWires, Resetn, R_in[4], Clock, r4);
    //regn reg_5 (BusWires, Resetn, R_in[5], Clock, r5);
    regn reg_6 (BusWires, Resetn, R_in[6]|lr_in, Clock, r6);

    // r7 is program counter
    // module pc_count(R, Resetn, Clock, E, L, Q);
    pc_count reg_pc (BusWires, Resetn, Clock, pc_incr, pc_in, pc);

    // r5 is stack pointer
    sp_count reg_sp(
        .R(BusWires), 
        .Resetn(Resetn),
        .Clock(Clock),
        .U(sp_incr),
        .D(sp_dec),
        .L(sp_in),
        .Q(r5)
    );

    regn reg_A (BusWires, Resetn, A_in, Clock, A);
    regn reg_DOUT (BusWires, Resetn, DOUT_in, Clock, DOUT);
    regn reg_ADDR (BusWires, Resetn, ADDR_in, Clock, ADDR);
    regn reg_IR (DIN, Resetn, IR_in, Clock, IR);

    flipflop reg_W (W_D, Resetn, Clock, W);

    barrel barrel(
        .shift_type(shift_type),
        .shift(BusWires[3:0]),
        .data_in(A),
        .data_out(shift_data_out)
    );
    
    // alu
    always @(*)
        if (ALU_and)
            Sum = A & BusWires;					// bitwise AND cond
        else if (do_shift)
            {Carry, Sum} = shift_data_out;
		else
            if (!AddSub)
               {Carry, Sum} = A + BusWires;
            else
               {Carry, Sum} = A + ~BusWires + 16'b1;
    regn reg_G (Sum, Resetn, G_in, Clock, G);

    // define the internal processor bus
    always @(*)
        case (Sel)
            _R0: BusWires = r0;
            _R1: BusWires = r1;
            _R2: BusWires = r2;
            _R3: BusWires = r3;
            _R4: BusWires = r4;
            _R5: BusWires = r5;
            _R6: BusWires = r6;
            _PC: BusWires = pc;
            _G: BusWires = G;
            _IR8_IR8_0: BusWires = {{7{IR[8]}}, IR[8:0]}; // sign extended
            _IR7_0_0: BusWires = {IR[7:0], 8'b0};
            _DIN: BusWires = DIN;
            _IR4: BusWires = {{12{IR[3]}}, IR[3:0]};
            default: BusWires = 16'bx;
        endcase
endmodule

module pc_count(R, Resetn, Clock, E, L, Q);
    input [15:0] R;
    input Resetn, Clock, E, L;
    output [15:0] Q;
    reg [15:0] Q;
   
    always @(posedge Clock)
        if (!Resetn)
            Q <= 16'b0;
        else if (L)
            Q <= R;
        else if (E)
            Q <= Q + 1'b1;
endmodule

module sp_count(R, Resetn, Clock, U, D, L, Q);
    input [15:0] R;
    input Resetn, Clock, U, D, L;
    output [15:0] Q;
    reg [15:0] Q;
   
    always @(posedge Clock)
        if (!Resetn)
            Q <= 16'b0;
        else if (L)
            Q <= R;
        else if (U)
            Q <= Q + 1'b1;
        else if (D)
            Q <= Q - 1'b1;
endmodule

module dec3to8(E, W, Y);
    input E; // enable
    input [2:0] W;
    output [0:7] Y;
    reg [0:7] Y;
   
    always @(*)
        if (E == 0)
            Y = 8'b00000000;
        else
            case (W)
                3'b000: Y = 8'b10000000;
                3'b001: Y = 8'b01000000;
                3'b010: Y = 8'b00100000;
                3'b011: Y = 8'b00010000;
                3'b100: Y = 8'b00001000;
                3'b101: Y = 8'b00000100;
                3'b110: Y = 8'b00000010;
                3'b111: Y = 8'b00000001;
            endcase
endmodule

module regn(R, Resetn, E, Clock, Q);
    parameter n = 16;
    input [n-1:0] R;
    input Resetn, E, Clock;
    output [n-1:0] Q;
    reg [n-1:0] Q;

    always @(posedge Clock)
        if (!Resetn)
            Q <= 0;
        else if (E)
            Q <= R;
endmodule
