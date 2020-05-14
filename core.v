`timescale 1ns / 1ps
module core(clk);
input clk; 
parameter NOP = 8'b00000000,
            LOAD_A = 4'b0010,
            LOAD_B = 4'b0001,
            STORE_A = 4'b0100,
            ADD = 4'b1000,
            SUB = 4'b1001,
            JUMP = 4'b1010,
            JUMP_NEG = 4'b1011,
            HALT = 4'b0000;
parameter S0 = 3'b000,
          S1 = 3'b001,
          S2 = 3'b010,
          S3 = 3'b011,
          S4 = 3'b100,
          S5 = 3'b101,
          S6 = 3'b110,
          S7 = 3'b111;
reg [7:0] RAM[0:15];    //内存空间
reg [7:0] regs[0:3];    //通用寄存器
reg [3:0] PC;   //程序计数器
reg [7:0] IFIDIR,IDEXIR,EXMEMIR,MEMWBIR;    //各级流水线的指令存储器
reg [7:0] EXMEMALUOut;      //alu计算结果储存
reg [7:0] IDEXA,IDEXB;      //alu两个输入
reg [7:0] RAM_DATA;
reg [7:0] MEMWBValue;       //要写回寄存器的值
reg [7:0] zero;             //0寄存器
wire [1:0] IFIDrs1,IFIDrs2;     //rs1和rs2
wire [3:0] RAM_addr;
wire [3:0] IDEXop,EXMEMop,MEMWBop ; //各级流水线的操作码
wire [1:0] MEMWBrd;         //写回的目标地址
wire[7:0] Ain,Bin;          //alu的输入
reg  [3:0]state;
wire [7:0]test_reg0,test_reg1,test_reg2,test_reg3; 
wire [7:0]test_ram13;
assign test_reg0 = regs[0];
assign test_reg1 = regs[1];
assign test_reg2 = regs[2];
assign test_reg3 = regs[3];
assign test_ram13 = RAM[13];
assign IDEXop = IDEXIR[7:4];
assign EXMEMop = EXMEMIR[7:4];
assign MEMWBop = MEMWBIR[7:4];
assign MEMWBrd = MEMWBIR[1:0];

assign IFIDrs1 = IFIDIR[3:2];
assign IFIDrs2 = IFIDIR[1:0];
assign Ain = IDEXA ;
assign Bin = IDEXB ;
assign RAM_addr = EXMEMALUOut[3:0];
initial
    begin
        state = 3'b000;
        PC = 4'b0000;
        IFIDIR = NOP;
        IDEXIR = NOP;
        IDEXA = 0;
        IDEXB = 0;
        EXMEMIR = NOP;
        EXMEMALUOut = 0;
        MEMWBIR = NOP;
        MEMWBValue = 0;

        //通用寄存器初始化
        regs[0] = 8'b0000_0000;
        regs[1] = 8'b0000_0000;
        regs[2] = 8'b0000_0000;
        regs[3] = 8'b0000_0000;
    end
    
initial 
    begin
        RAM[0] = 8'b0010_1110;
        RAM[1] = 8'b0001_1111;
        RAM[2] = 8'b1000_0100;
        RAM[3] = 8'b1010_0010;
        RAM[4] = 8'b0000_0000;
        RAM[5] = 8'b0000_0000;
        RAM[6] = 8'b0000_0000;
        RAM[7] = 8'b0000_0000;
        RAM[8] = 8'b0000_0000;
        RAM[9] = 8'b0000_0000;
        RAM[10]= 8'b0000_0000;
        RAM[11]= 8'b0000_0000;
        RAM[12]= 8'b0000_0000;
        RAM[13]= 8'b0000_0000;
        RAM[14]= 8'b0000_0001;
        RAM[15]= 8'b0000_0001;
    end

always @(posedge clk)
    begin
    case (state)
    S0:
    begin
    //第一级 IFID 
    IFIDIR <= RAM[PC];  //将PC值对应地址读取到IFIDIR寄存器中
    if(IFIDIR == HALT)
        state <=S0;
    else
        begin
            PC <= PC + 1;       //PC值+1
            state <= S1;
        end
    end

    S1:
    begin
    //第二级流水线IDEX
    IDEXA <= regs[IFIDrs1]; //读取两个操作数
    IDEXB <= regs[IFIDrs2]; 
    IDEXIR <= IFIDIR;       //IDEXIR传递
    state <= S2;
    end

    S2:
    begin
    //第三级 EXMEM
    if (IDEXop ==  ADD)
        EXMEMALUOut <= Ain + Bin;
     else if (IDEXop ==  SUB)
        EXMEMALUOut <= Ain - Bin;
     else if (IDEXop ==HALT)
        EXMEMALUOut <= 8'b0000_0000;
    else
        EXMEMALUOut <= {4'b0000, IDEXIR[3:0]};
     EXMEMIR <=IDEXIR;
     state<= S3;
    end

    S3:
    begin
     //第四级 MEMWB
     if ((EXMEMop == ADD)||(EXMEMop  ==SUB)) MEMWBValue <= EXMEMALUOut;
     else if((EXMEMop == LOAD_A)||(EXMEMop ==LOAD_B))  MEMWBValue <= RAM[RAM_addr];
     else if (EXMEMop == STORE_A)   RAM[RAM_addr]<= regs[0];
     else if(EXMEMop == JUMP)  PC<= RAM_addr;
     else MEMWBValue <= NOP;
    MEMWBIR <= EXMEMIR;
    state <= S4;
    end

    S4:
    begin
    //第五级 WB
    case(MEMWBop)
    ADD:     regs[MEMWBrd] <= MEMWBValue;
    SUB:     regs[MEMWBrd] <= MEMWBValue;
    LOAD_A:  regs[0]       <= MEMWBValue; 
    LOAD_B:  regs[1]       <= MEMWBValue;
    endcase
    state <= S0;
    end


    endcase
    end
    

endmodule
