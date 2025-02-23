`timescale 1ns / 1ps

module BranchUnit #(
    parameter PC_W = 9
) (
    input logic [PC_W-1:0] Cur_PC,
    input logic [31:0] Imm,
    input logic Branch,
    input logic [31:0] AluResult,
    output logic [31:0] PC_Imm,
    output logic [31:0] PC_Four,
    output logic [31:0] BrPC,
    output logic PcSel,

    input logic EhJAL, // Para saber se eh JAL
    input logic EhJALR, // Para saber se eh JALR
    input logic [2:0] Funct3, // Vou usar para saber qual o tipo de Desvio que deve ser feito 
    input logic [6:0] opcode // Para diferenciar BEQ de JALR
);

  logic Branch_Sel;
  logic [31:0] PC_Full;

    assign PC_Full = {23'b0, Cur_PC}; // Aqui eh feita uma concatenacao de vetores para expandir Cur_PC a ter 32 bits (32 - 9 = 23)

  assign PC_Imm = PC_Full + Imm;
  assign PC_Four = PC_Full + 32'b100;

  // Determinando se alguma condicao de branch foi acionada, usando o Funct3 para saber o que fazer
  always_comb begin
    if (EhJALR) begin //BEQ -> Desvio se SrcA == SrcB (Aqui tem problema, o Funct3 de BEQ e de JALR sao iguais, tenho que tratar)
      Branch_Sel = 1;
    end else begin
      case(Funct3)
        3'b000: Branch_Sel = Branch && AluResult; // De fato o BEQ
        3'b001: Branch_Sel = Branch && !AluResult; // BNE -> Desvio se SrcA != SrcB
        3'b100: Branch_Sel = Branch && AluResult; // BLT -> Desvio se SrcA < SrcB
        3'b101: Branch_Sel = Branch && !AluResult; // BGE -> BGE: Desvio se SrcA >= SrcB
        default: Branch_Sel = 0; // Nao eh uma instrucao de branch
      endcase
    end
  end

  // Calculando o o valor do próximo PC
  always_comb begin
    if(EhJAL || EhJALR || Branch_Sel) begin
      BrPC = PC_Imm;
      PcSel = 1;
    end else begin
      BrPC = 32'b0;
      PcSel = 0;
    end
  end

endmodule
