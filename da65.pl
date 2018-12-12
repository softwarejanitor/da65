#!/usr/bin/perl -w

#
# da65.pl
#
# Simple 65C02 mini-disassembler.
#
# 20181105 LSH
#

my @bytes = ();

my $base = 0;

my %opcodes = (
  # Mnemonic	Addressing mode	Form		Opcode	Size	Timing
  # ADC		Immediate	ADC #Oper	69	2	2
  0x69 => {
    'modesub' => \&mode_Immediate,
    'mnemonic' => 'ADC'
  },
  # 		Zero Page	ADC Zpg		65	2	3
  0x65 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'ADC'
  },
  # 		Zero Page,X	ADC Zpg,X	75	2	4
  0x75 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'ADC'
  },
  # 		Absolute	ADC Abs		6D	3	4
  0x6d => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'ADC'
  },
  # 		Absolute,X	ADC Abs,X	7D	3	4
  0x7d => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'ADC'
  },
  # 		Absolute,Y	ADC Abs,Y	79	3	4
  0x79 => {
    'modesub' => \&mode_Absolute_Y,
    'mnemonic' => 'ADC'
  },
  # 		(Zero Page,X)	ADC (Zpg,X)	61	2	6
  0x61 => {
    'modesub' => \&mode_Indirect_Zero_Page_X,
    'mnemonic' => 'ADC'
  },
  # 		(Zero Page),Y	ADC (Zpg),Y	71	2	5
  0x71 => {
    'modesub' => \&mode_Indirect_Zero_Page_Y,
    'mnemonic' => 'ADC'
  },
  # 		(Zero Page)	ADC (Zpg)	72	2	5
  0x72 => {
    'modesub' => \&mode_Indirect_Zero_Page,
    'mnemonic' => 'ADC'
  },
  # AND		Immediate	AND #Oper	29	2	2
    0x29 => {
    'modesub' => \&mode_Immediate,
    'mnemonic' => 'AND'
  },
  # 		Zero Page	AND Zpg		25	2	3
  0x25 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'AND'
  },
  # 		Zero Page,X	AND Zpg,X	35	2	4
  0x35 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'AND'
  },
  # 		Absolute	AND Abs		2D	3	4
  0x2d => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'AND'
  },
  # 		Absolute,X	AND Abs,X	3D	3	4
  0x3d => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'AND'
  },
  # 		Absolute,Y	AND Abs,Y	39	3	4
  0x39 => {
    'modesub' => \&mode_Absolute_Y,
    'mnemonic' => 'AND'
  },
  # 		(Zero Page,X)	AND (Zpg,X)	21	2	6
  0x31 => {
    'modesub' => \&mode_Indirect_Zero_Page_X,
    'mnemonic' => 'AND'
  },
  # 		(Zero Page),Y	AND (Zpg),Y	31	2	5
  0x32 => {
    'modesub' => \&mode_Indirect_Zero_Page_Y,
    'mnemonic' => 'AND'
  },
  # 		(Zero Page)	AND (Zpg)	32	2	5
  0x32 => {
    'modesub' => \&mode_Indirect_Zero_Page,
    'mnemonic' => 'ADC'
  },
  # ASL		Accumulator	ASL A		0A	1	2
  0x0a => {
    'modesub' => \&mode_Accumulator,
    'mnemonic' => 'ADC',
    'operand' => 'A'
  },
  # 		Zero Page	ASL Zpg		06	2	5
  0x06 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'ASL'
  },
  # 		Zero Page,X	ASL Zpg,X	16	2	6
  0x16 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'ASL'
  },
  # 		Absolute	ASL Abs		0E	3	6
  0x0e => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'ASL'
  },
  # 		Absolute,X	ASL Abs,X	1E	3	7
  0x1e => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'ASL'
  },
  # BBR0	Relative	BBR0 Oper	0F	2	2
  0x0f => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBR0'
  },
  # BBR1	Relative	BBR1 Oper	1F	2	2
  0x1f => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBR1'
  },
  # BBR2	Relative	BBR2 Oper	2F	2	2
  0x2f => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBR2'
  },
  # BBR3	Relative	BBR3 Oper	3F	2	2
  0x3f => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBR3'
  },
  # BBR4	Relative	BBR4 Oper	4F	2	2
  0x4f => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBR4'
  },
  # BBR5	Relative	BBR5 Oper	5F	2	2
  0x5f => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBR5'
  },
  # BBR6	Relative	BBR6 Oper	6F	2	2
  0x6f => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBR6'
  },
  # BBR7	Relative	BBR7 Oper	7F	2	2
  0x7f => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBR7'
  },
  # BBS0	Relative	BBS0 Oper	8F	2	2
  0x8f => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBS0'
  },
  # BBS1	Relative	BBS1 Oper	9F	2	2
  0x9f => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBS1'
  },
  # BBS2	Relative	BBS2 Oper	AF	2	2
  0xaf => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBS2'
  },
  # BBS3	Relative	BBS3 Oper	BF	2	2
  0xbf => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBS3'
  },
  # BBS4	Relative	BBS4 Oper	CF	2	2
  0xcf => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBS4'
  },
  # BBS5	Relative	BBS5 Oper	DF	2	2
  0xdf => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBS5'
  },
  # BBS6	Relative	BBS6 Oper	EF	2	2
  0x3f => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBS6'
  },
  # BBS7	Relative	BBS7 Oper	FF	2	2
  0xff => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BBS7'
  },
  # BCC		Relative	BCC Oper	90	2	2
  0x90 => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BCC'
  },
  # BCS		Relative	BCS Oper	B0	2	2
  0xB0 => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BCS'
  },
  # BEQ		Relative	BEQ Oper	F0	2	2
  0xF0 => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BEQ'
  },
  # BIT		Immediate	BIT #Oper	89	2	2
  0x89 => {
    'modesub' => \&mode_Immediate,
    'mnemonic' => 'BIT'
  },
  #	 	Zero Page	BIT Zpg		24	2	3
  0x24 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'BIT'
  },
  # 		Zero Page,X	BIT Zpg,X	34	2	4
  0x34 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'BIT'
  },
  # 		Absolute	BIT Abs		2C	3	4
  0x2c => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'BIT'
  },
  # 		Absolute,X	BIT Abs,X	3C	3	4
  0x3c => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'BIT'
  },
  # BMI		Relative	BMI Oper	30	2	2
  0x30 => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BMI'
  },
  # BNE		Relative	BNE Oper	D0	2	2
  0xd0 => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BNE'
  },
  # BPL		Relative	BPL Oper	10	2	2
  0x10 => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BPL'
  },
  # BRA		Relative	BRA Oper	80	2	3
  0x80 => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BRA'
  },
  # BRK		Implied		BRK		00	1	7
  0x00 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'BRK'
  },
  # BVC		Relative	BVC Oper	50	2	2
  0x50 => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BVC'
  },
  # BVS		Relative	BVS Oper	70	2	2
  0x70 => {
    'modesub' => \&mode_Relative,
    'mnemonic' => 'BVS'
  },
  # CLC		Implied		CLC		18	1	2
  0x18 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'CLC'
  },
  # CLD		Implied		CLD		D8	1	2
  0xd8 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'CLD'
  },
  # CLI		Implied		CLI		58	1	2
  0xd5 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'CLI'
  },
  # CLV		Implied		CLV		B8	1	2
  0xb5 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'CLV'
  },
  # CMP		Immediate	CMP #Oper	C9	2	2
  0xc9 => {
    'modesub' => \&mode_Immediate,
    'mnemonic' => 'CMP'
  },
  # 		Zero Page	CMP Zpg		C5	2	3
  0xc5 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'CMP'
  },
  # 		Zero Page,X	CMP Zpg		D5	2	4
  0xd5 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'CMP'
  },
  # 		Absolute	CMP Abs		CD	3	4
  0xcd => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'CMP'
  },
  # 		Absolute,X	CMP Abs,X	DD	3	4
  0xdd => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'CMP'
  },
  # 		Absolute,Y	CMP Abs,Y	D9	3	4
  0xd9 => {
    'modesub' => \&mode_Absolute_Y,
    'mnemonic' => 'CMP'
  },
  # 		(Zero Page,X)	CMP (Zpg,X)	C1	2	6
  0xc1 => {
    'modesub' => \&mode_Indirect_Zero_Page_X,
    'mnemonic' => 'CMP'
  },
  # 		(Zero Page),Y	CMP (Zpg),Y	D1	2	5
  0xd1 => {
    'modesub' => \&mode_Indirect_Zero_Page_Y,
    'mnemonic' => 'CMP'
  },
  # 		(Zero Page)	CMP (Zpg)	D2	2	5
  0xd2 => {
    'modesub' => \&mode_Indirect_Zero_Page,
    'mnemonic' => 'CMP'
  },
  # CPX		Immediate	CPX #Oper	E0	2	2
  0xe0 => {
    'modesub' => \&mode_Immediate,
    'mnemonic' => 'CPX'
  },
  # 		Zero Page	CPX Zpg		E4	2	3
  0xe4 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'CPA'
  },
  # 		Absolute	CPX Abs		EC	3	4
  0xec => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'CPX'
  },
  # CPY		Immediate	CPY #Oper	C0	2	2
  0xc0 => {
    'modesub' => \&mode_Immediate,
    'mnemonic' => 'CPY'
  },
  # 		Zero Page	CPY Zpg		C4	2	3
  0xc4 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'CPY'
  },
  # 		Absolute	CPY Abs		CC	3	4
  0xcc => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'CPY'
  },
  # DEA		Accumulator	DEA		3A	1	2
  0x3a => {
    'modesub' => \&mode_Accumulator,
    'mnemonic' => 'DEA'
  },
  # DEC		Zero Page	DEC Zpg		C6	2	5
  0xc6 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'DEC'
  },
  # 		Zero Page,X	DEC Zpg,X	D6	2	6
  0xd6 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'DEC'
  },
  # 		Absolute	DEC Abs		CE	3	6
  0xce => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'DEC'
  },
  # 		Absolute,X	DEC Abs,X	DE	3	7
  0xde => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'DEC'
  },
  # DEX		Implied		DEX		CA	1	2
  0xca => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'DEX'
  },
  # DEY		Implied		DEY		88	1	2
  0x88 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'DEY'
  },
  # EOR		Immediate	EOR #Oper	49	2	2
  0x49 => {
    'modesub' => \&mode_Immediate,
    'mnemonic' => 'EOR'
  },
  # 		Zero Page	EOR Zpg		45	2	3
  0x45 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'EOR'
  },
  # 		Zero Page,X	EOR Zpg,X	55	2	4
  0x55 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'EOR'
  },
  # 		Absolute	EOR Abs		4D	3	4
  0x4d => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'EOR'
  },
  # 		Absolute,X	EOR Abs,X	5D	3	4
  0x5d => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'EOR'
  },
  # 		Absolute,Y	EOR Abs,Y	59	3	4
  0x59 => {
    'modesub' => \&mode_Absolute_Y,
    'mnemonic' => 'EOR'
  },
  # 		(Zero Page,X)	EOR (Zpg,X)	41	2	6
  0x41 => {
    'modesub' => \&mode_Indirect_Zero_Page_X,
    'mnemonic' => 'EOR'
  },
  # 		(Zero Page),Y	EOR (Zpg),Y	51	2	5
  0x51 => {
    'modesub' => \&mode_Indirect_Zero_Page_Y,
    'mnemonic' => 'EOR'
  },
  # 		(Zero Page)	EOR (Zpg)	52	2	5
  0x52 => {
    'modesub' => \&mode_Indirect_Zero_Page,
    'mnemonic' => 'EOR'
  },
  # INA		Accumulator	INA		1A	1	2
  0x1a => {
    'modesub' => \&mode_Accumulator,
    'mnemonic' => 'INA'
  },
  # INC		Zero Page	INC Zpg		E6	2	5
  0xe6 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'INC'
  },
  # 		Zero Page,X	INC Zpg,X	F6	2	6
  0xf6 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'INC'
  },
  # 		Absolute	INC Abs		EE	3	6
  0xee => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'INC'
  },
  # 		Absolute,X	INC Abs,X	FE	3	7
  0xfe => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'INC'
  },
  # INX		Implied		INX		E8	1	2
  0xe8 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'INX'
  },
  # INY		Implied		INY		C8	1	2
  0xc8 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'INY'
  },
  # JMP		Absolute	JMP Abs		4C	3	3
  0x4c => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'JMP'
  },
  # 		(Absolute)	JMP (Abs)	6C	3	5
  0x6c => {
    'modesub' => \&mode_Indirect_Absolute,
    'mnemonic' => 'JMP'
  },
  # 		(Absolute,X)	JMP (Abs,X)	7C	3	6
  0x7c => {
    'modesub' => \&mode_Indirect_Absolute_X,
    'mnemonic' => 'JMP'
  },
  # JSR		Absolute	JSR Abs		20	3	6
  0x20 => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'JSR'
  },
  # LDA		Immediate	LDA #Oper	A9	2	2
  0xa9 => {
    'modesub' => \&mode_Immediate,
    'mnemonic' => 'LDA'
  },
  # 		Zero Page	LDA Zpg		A5	2	3
  0xa5 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'LDA'
  },
  # 		Zero Page,X	LDA Zpg,X	B5	2	4
  0xb5 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'LDA'
  },
  # 		Absolute	LDA Abs		AD	3	4
  0xad => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'LDA'
  },
  # 		Absolute,X	LDA Abs,X	BD	3	4
  0xbd => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'LDA'
  },
  # 		Absolute,Y	LDA Abs,Y	B9	3	4
  0xb9 => {
    'modesub' => \&mode_Absolute_Y,
    'mnemonic' => 'LDA'
  },
  # 		(Zero Page,X)	LDA (Zpg,X)	A1	2	6
  0xa1 => {
    'modesub' => \&mode_Indirect_Zero_Page_X,
    'mnemonic' => 'LDA'
  },
  # 		(Zero Page),Y	LDA (Zpg),Y	B1	2	5
  0xb1 => {
    'modesub' => \&mode_Indirect_Zero_Page_Y,
    'mnemonic' => 'LDA'
  },
  # 		(Zero Page)	LDA (Zpg)	B2	2	5
  0xb2 => {
    'modesub' => \&mode_Indirect_Zero_Page,
    'mnemonic' => 'LDA'
  },
  # LDX		Immediate	LDX #Oper	A2	2	2
  0xa2 => {
    'modesub' => \&mode_Immediate,
    'mnemonic' => 'LDX'
  },
  # 		Zero Page	LDX Zpg		A6	2	3
  0xa6 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'LDX'
  },
  # 		Zero Page,Y	LDX Zpg,Y	B6	2	4
  0xb6 => {
    'modesub' => \&mode_Zero_Page_Y,
    'mnemonic' => 'LDX'
  },
  # 		Absolute	LDX Abs		AE	3	4
  0xae => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'LDX'
  },
  # 		Absolute,Y	LDX Abs,Y	BE	3	4
  0xbe => {
    'modesub' => \&mode_Absolute_Y,
    'mnemonic' => 'LDX'
  },
  # LDY		Immediate	LDY #Oper	A0	2	2
  0xa0 => {
    'modesub' => \&mode_Immediate,
    'mnemonic' => 'LDY'
  },
  # 		Zero Page	LDY Zpg		A4	2	3
  0xa4 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'LDY'
  },
  # 		Zero Page,Y	LDY Zpg,X	B4	2	4
  0xb4 => {
    'modesub' => \&mode_Zero_Page_Y,
    'mnemonic' => 'LDY'
  },
  # 		Absolute	LDY Abs		AC	3	4
  0xac => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'LDY'
  },
  # 		Absolute,Y	LDY Abs,X	BC	3	4
  0xbc => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'LDY'
  },
  # LSR		Accumulator	LSR A		4A	1	2
  0x4a => {
    'modesub' => \&mode_Accumulator,
    'mnemonic' => 'LSR',
    'operand' => 'A'
  },
  # 		Zero Page	LSR Zpg		46	2	5
  0x46 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'LSR'
  },
  # 		Zero Page,X	LSR Zpg,X	56	2	6
  0x56 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'LSR'
  },
  # 		Absolute	LSR Abs		4E	3	6
  0x4e => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'LSR'
  },
  # 		Absolute,X	LSR Abs,X	5E	3	7
  0x5e => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'LSR'
  },
  # NOP		Implied		NOP		EA	1	2
  0xea => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'NOP'
  },
  # ORA		Immediate	ORA #Oper	09	2	2
  0x09 => {
    'modesub' => \&mode_Immediate,
    'mnemonic' => 'ORA'
  },
  # 		Zero Page	ORA Zpg		05	2	3
  0x05 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'ORA'
  },
  # 		Zero Page,X	ORA Zpg,X	15	2	4
  0x15 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'ORA'
  },
  # 		Absolute	ORA Abs		0D	3	4
  0x0d => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'ORA'
  },
  # 		Absolute,X	ORA Abs,X	1D	3	4
  0x1d => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'ORA'
  },
  # 		Absolute,Y	ORA Abs,Y	19	3	4
  0x19 => {
    'modesub' => \&mode_Absolute_Y,
    'mnemonic' => 'ORA'
  },
  # 		(Zero Page,X)	ORA (Zpg,X)	01	2	6
  0x01 => {
    'modesub' => \&mode_Indirect_Zero_Page_X,
    'mnemonic' => 'ORA'
  },
  # 		(Zero Page),Y	ORA (Zpg),Y	11	2	5
  0x11 => {
    'modesub' => \&mode_Indirect_Zero_Page_Y,
    'mnemonic' => 'ORA'
  },
  # 		(Zero Page)	ORA (Zpg)	12	2	5
  0x12 => {
    'modesub' => \&mode_Indirect_Zero_Page,
    'mnemonic' => 'ORA'
  },
  # PHA		Implied		PHA		48	1	3
  0x48 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'PHA'
  },
  # PHX		Implied		PHX		DA	1	3
  0xda => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'PHX'
  },
  # PHY		Implied		PHY		5A	1	3
  0x5a => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'PHY'
  },
  # PLA		Implied		PLA		68	1	4
  0x68 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'PLA'
  },
  # PLX		Implied		PLX		FA	1	4
  0xfa => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'PLX'
  },
  # PLY		Implied		PLY		7A	1	4
  0x7a => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'PLY'
  },
  # ROL		Accumulator	ROL A		2A	1	2
  0x2a => {
    'modesub' => \&mode_Accumulator,
    'mnemonic' => 'ROL',
    'operand' => 'A'
  },
  # 		Zero Page	ROL Zpg		26	2	5
  0x26 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'ROL'
  },
  # 		Zero Page,X	ROL Zpg,X	36	2	6
  0x36 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'ROL'
  },
  # 		Absolute	ROL Abs		2E	3	6
  0x2e => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'ROL'
  },
  # 		Absolute,X	ROL Abs,X	3E	3	7
  0x3e => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'ROL'
  },
  # ROR		Accumulator	ROR A		6A	1	2
  0x6a => {
    'modesub' => \&mode_Accumulator,
    'mnemonic' => 'ROR',
    'operand' => 'A'
  },
  # 		Zero Page	ROR Zpg		66	2	5
  0x6a => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'ROR'
  },
  # 		Zero Page,X	ROR Zpg,X	76	2	6
  0x76 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'ROR'
  },
  # 		Absolute	ROR Abs		6E	3	6
  0x6e => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'ROR'
  },
  # 		Absolute,X	ROR Abs,X	7E	3	7
  0x7e => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'ROR'
  },
  # RTI		Implied		RTI		40	1	6
  0x40 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'RTI'
  },
  # RTS		Implied		RTS		60	1	6
  0x60 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'RTS'
  },
  # SBC		Immediate	SBC #Oper	E9	2	2
  0xe9 => {
    'modesub' => \&mode_Immediate,
    'mnemonic' => 'SBC'
  },
  # 		Zero Page	SBC Zpg		E5	2	3
  0xe5 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'SBC'
  },
  # 		Zero Page,X	SBC Zpg,X	F5	2	4
  0xf5 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'SBC'
  },
  # 		Absolute	SBC Abs		ED	3	4
  0xed => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'SBC'
  },
  # 		Absolute,X	SBC Abs,X	FD	3	4
  0xfd => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'SBC'
  },
  # 		Absolute,Y	SBC Abs,Y	F9	3	4
  0xf9 => {
    'modesub' => \&mode_Absolute_Y,
    'mnemonic' => 'SBC'
  },
  # 		(Zero Page,X)	SBC (Zpg,X)	E1	2	6
  0xe1 => {
    'modesub' => \&mode_Indirect_Zero_Page_X,
    'mnemonic' => 'SBC'
  },
  # 		(Zero Page),Y	SBC (Zpg),Y	F1	2	5
  0xf1 => {
    'modesub' => \&mode_Indirect_Zero_Page_Y,
    'mnemonic' => 'SBC'
  },
  # 		(Zero Page)	SBC (Zpg)	F2	2	5
  0xf2 => {
    'modesub' => \&mode_Indirect_Zero_Page,
    'mnemonic' => 'SBC'
  },
  # SEC		Implied		SEC		38	1	2
  0x38 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'SEC'
  },
  # SED		Implied		SED		F8	1	2
  0xf8 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'SED'
  },
  # SEI		Implied		SEI		78	1	2
  0x78 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'SEI'
  },
  # STA		Zero Page	STA Zpg		85	2	3
  0x85 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'STA'
  },
  # 		Zero Page,X	STA Zpg,X	95	2	4
  0x95 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'STA'
  },
  # 		Absolute	STA Abs		8D	3	4
  0x8d => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'STA'
  },
  # 		Absolute,X	STA Abs,X	9D	3	5
  0x9d => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'STA'
  },
  # 		Absolute,Y	STA Abs,Y	99	3	5
  0x99 => {
    'modesub' => \&mode_Absolute_Y,
    'mnemonic' => 'STA'
  },
  # 		(Zero Page,X)	STA (Zpg,X)	81	2	6
  0x81 => {
    'modesub' => \&mode_Indirect_Zero_Page_X,
    'mnemonic' => 'STA'
  },
  # 		(Zero Page),Y	STA (Zpg),Y	91	2	6
  0x91 => {
    'modesub' => \&mode_Indirect_Zero_Page_Y,
    'mnemonic' => 'STA'
  },
  # 		(Zero Page)	STA (Zpg)	92	2	5
  0x92 => {
    'modesub' => \&mode_Indirect_Zero_Page,
    'mnemonic' => 'STA'
  },
  # STX		Zero Page	STX Zpg		86	2	3
  0x86 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'STX'
  },
  # 		Zero Page,Y	STX Zpg,Y	96	2	4
  0x96 => {
    'modesub' => \&mode_Zero_Page_Y,
    'mnemonic' => 'STX'
  },
  # 		Absolute	STX Abs		8E	3	4
  0x8e => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'STX'
  },
  # STY		Zero Page	STY Zpg		84	2	3
  0x84 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'STY'
  },
  # 		Zero Page,X	STY Zpg,X	94	2	4
  0x94 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'STY'
  },
  # 		Absolute	STY Abs		8C	3	4
  0x8c => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'STY'
  },
  # STZ		Zero Page	STZ Zpg		64	2	3
  0x64 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'STZ'
  },
  # 		Zero Page,X	STZ Zpg,X	74	2	4
  0x74 => {
    'modesub' => \&mode_Zero_Page_X,
    'mnemonic' => 'STZ'
  },
  # 		Absolute	STZ Abs		9C	3	4
  0x9c => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'STZ'
  },
  # 		Absolute,X	STZ Abs,X	9E	3	5
  0x9e => {
    'modesub' => \&mode_Absolute_X,
    'mnemonic' => 'STZ'
  },
  # TAX		Implied		TAX		AA	1	2
  0xaa => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'TAX'
  },
  # TAY		Implied		TAY		A8	1	2
  0xa8 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'TAY'
  },
  # TRB		Zero Page	TRB Zpg		14	2	5
  0x14 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'TRB'
  },
  # 		Absolute	TRB Abs		1C	3	6
  0x1c => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'TRB'
  },
  # TSB		Zero Page	TSB Zpg		04	2	5
  0x04 => {
    'modesub' => \&mode_Zero_Page,
    'mnemonic' => 'TSB'
  },
  # 		Absolute	TSB Abs		0C	3	6
  0x0c => {
    'modesub' => \&mode_Absolute,
    'mnemonic' => 'TSB'
  },
  # TSX		Implied		TSX		BA	1	2
  0xba => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'TSX'
  },
  # TXA		Implied		TXA		8A	1	2
  0x8a => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'TXA'
  },
  # TXS		Implied		TXS		9A	1	2
  0x9a => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'TXS'
  },
  # TYA		Implied		TYA		98	1	2
  0x98 => {
    'modesub' => \&mode_Implied,
    'mnemonic' => 'TYA'
  }
);

die "Usage: da65.pl [input]\n" unless defined $ARGV[0];

my $input_mode = 0;

# Process command line arguments.
while (defined $ARGV[0] && $ARGV[0] =~ /^-/) {
  # Set base address in decimal.
  if ($ARGV[0] eq '-a' && defined $ARGV[1] && $ARGV[1] =~ /^\d+$/) {
    $base = $ARGV[1];
    shift;
    shift;
  # Set base address in hex.
  } elsif ($ARGV[0] eq '-x' && defined $ARGV[1] && $ARGV[1] =~ /^[a-z0-9A-Z]+$/) {
    $base = hex($ARGV[1]);
    shift;
    shift;
  } elsif ($ARGV[0] eq '-i') {
    $input_mode = 1;
    shift;
  } else {
    die "Invalid argument $ARGV[0]\n";
  }
}

#print "base=$base\n";

my $input_file = shift;

die "Must supply filename\n" unless defined $input_file && $input_file;

sub mode_Immediate {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s #\$%02x\n", $addr + $base, $instr, $bytes[$addr + 1]);
  } else {
    print uc sprintf("%08x  %02x %02x      %3.3s #\$%02x\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $instr, $bytes[$addr + 1]);
  }
  $_[0] += 2;
}

sub mode_Zero_Page {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s \$%02x\n", $addr + $base, $instr, $bytes[$addr + 1]);
  } else {
    print uc sprintf("%08x  %02x %02x      %3.3s \$%02x\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $instr, $bytes[$addr + 1]);
  }
  $_[0] += 2;
}

sub mode_Zero_Page_X {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s \$%02x,X\n", $addr + $base, $instr, $bytes[$addr + 1]);
  } else {
    print uc sprintf("%08x  %02x %02x  %3.3s \$%02x,X\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $instr, $bytes[$addr + 1]);
  }
  $_[0] += 2;
}

sub mode_Zero_Page_Y {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s \$%02x,Y\n", $addr + $base, $instr, $bytes[$addr + 1]);
  } else {
    print uc sprintf("%08x  %02x %02x      %3.3s \$%02x,Y\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $instr, $bytes[$addr + 1]);
  }
  $_[0] += 2;
}

sub mode_Absolute {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s \$%02x%02x\n", $addr + $base, $instr, $bytes[$addr + 2], $bytes[$addr + 1]);
  } else {
    print uc sprintf("%08x  %02x %02x %02x   %3.3s \$%02x%02x\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $bytes[$addr + 2], $instr, $bytes[$addr + 2], $bytes[$addr + 1]);
  }
  $_[0] += 3;
}

sub mode_Indirect_Absolute {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s (\$%02x%02x)\n", $addr + $base, $instr, $bytes[$addr + 2], $bytes[$addr + 1]);
  } else {
    print uc sprintf("%08x  %02x %02x %02x   %3.3s (\$%02x%02x)\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $bytes[$addr + 2], $instr, $bytes[$addr + 2], $bytes[$addr + 1]);
  }
  $_[0] += 3;
}

sub mode_Indirect_Absolute_X {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s (\$%02x%02x,X)\n", $addr + $base, $instr, $bytes[$addr + 2], $bytes[$addr + 1]);
  } else {
    print uc sprintf("%08x  %02x %02x %02x   %3.3s (\$%02x%02x,X)\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $bytes[$addr + 2], $instr, $bytes[$addr + 2], $bytes[$addr + 1]);
  }
  $_[0] += 3;
}

sub mode_Absolute_X {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s \$%02x%02x,X\n", $addr + $base, $instr, $bytes[$addr + 2], $bytes[$addr + 1]);
  } else {
    print uc sprintf("%08x  %02x %02x %02x   %3.3s \$%02x%02x,X\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $bytes[$addr + 2], $instr, $bytes[$addr + 2], $bytes[$addr + 1]);
  }
  $_[0] += 3;
}

sub mode_Absolute_Y {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s \$%02x%02x,Y\n", $addr + $base, $instr, $bytes[$addr + 2], $bytes[$addr + 1]);
  } else {
    print uc sprintf("%08x  %02x %02x %02x   %3.3s \$%02x%02x,Y\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $bytes[$addr + 2], $instr, $bytes[$addr + 2], $bytes[$addr + 1]);
  }
  $_[0] += 3;
}

sub mode_Indirect_Zero_Page_X {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s (\$%02x,X)\n", $addr + $base, $instr, $bytes[$addr + 1]);
  } else {
    print uc sprintf("%08x  %02x %02x      %3.3s (\$%02x,X)\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $instr, $bytes[$addr + 1]);
  }
  $_[0] += 2;
}

sub mode_Indirect_Zero_Page_Y {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s (\$%02x),Y\n", $addr + $base, $instr, $bytes[$addr + 1]);
  } else {
    print uc sprintf("%08x  %02x %02x      %3.3s (\$%02x),Y\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $instr, $bytes[$addr + 1]);
  }
  $_[0] += 2;
}

sub mode_Indirect_Zero_Page {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s (\$%02x)\n", $addr + $base, $instr, $bytes[$addr + 1]);
  } else {
    print uc sprintf("%08x  %02x %02x      %3.3s (\$%02x)\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $instr, $bytes[$addr + 1]);
  }
  $_[0] += 2;
}

sub mode_Relative {
  my ($addr, $instr) = @_;
  my $rel = ($addr + $base) - (255 - $bytes[$addr + 1] - 1);
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s \$%04x\n", $addr + $base, $instr, $rel);
  } else {
    print uc sprintf("%08x  %02x %02x      %3.3s \$%04x\n", $addr + $base, $bytes[$addr], $bytes[$addr + 1], $instr, $rel);
  }
  $_[0] += 2;
}

sub mode_Implied {
  my ($addr, $instr) = @_;
  if ($input_mode) {
    print uc sprintf("%04x:    %3.3s\n", $addr + $base, $instr);
  } else {
    print uc sprintf("%08x  %02x         %3.3s\n", $addr + $base, $bytes[$addr], $instr);
  }
  $_[0]++;
}

sub mode_Accumulator {
  my ($addr, $instr, $operand) = @_;
  if ($input_mode) {
    if (defined $operand) {
      print uc sprintf("%04x:    %3.3s %s\n", $addr + $base, $instr, $operand);
    } else {
      print uc sprintf("%04x:    %3.3s\n", $addr + $base, $instr);
    }
  } else {
    if (defined $operand) {
      print uc sprintf("%08x  %02x         %3.3s %s\n", $addr + $base, $bytes[$addr], $instr, $operand);
    } else {
      print uc sprintf("%08x  %02x         %3.3s\n", $addr + $base, $bytes[$addr], $instr);
    }
  }
  $_[0]++;
}

# Get the file size.
my $expected = -s $input_file;

my $fh,
my $buffer = '';

# Open the input file.
if (open($fh, "<$input_file")) {
  binmode $fh;

  # Read the input file.
  my $size = read($fh, $buffer, $expected);

  if ($size != $expected) {
    print "Error reading $input_file, got $size, expected $expected\n";
  }

  # Close the file when we are done.
  close $fh;

  # Unpack the data into an array of bytes.
  @bytes = unpack "C$size", $buffer;

  # Traverse the data.
  my $addr = 0;
  #print "; addr = $addr \$" . sprintf("%06x", $addr) . "\n";
  #print "; size = $size \$" . sprintf("%06x", $size) . "\n";
  while ($addr < $size) {
    # Decode the instructions.
    if (defined $opcodes{$bytes[$addr]}{'modesub'}) {
      my $func = $opcodes{$bytes[$addr]}{'modesub'};
      $func->($addr, $opcodes{$bytes[$addr]}{'mnemonic'}, $opcodes{$bytes[$addr]}{'operand'});
    } else {
      # Undefined instructions.
      mode_Implied($addr, '???');
    }
  }
} else {
  die "Can't open $input_file\n";
}

1;

