#include "sim.h"

void parse_elf(const char *elf_file)
{
    
    if(elf_file == NULL) return;
    
    FILE *fp;
    fp = fopen(elf_file, "rb");
    
    if(fp == NULL)
    {
        printf("failed to open the elf file!\n");
        exit(0);
    }
	
    Elf32_Ehdr edhr;
	
    if(fread(&edhr, sizeof(Elf32_Ehdr), 1, fp) <= 0)
    {
        printf("fail to read the elf_head!\n");
        exit(0);
    }

    if(edhr.e_ident[0] != 0x7f || edhr.e_ident[1] != 'E' || 
       edhr.e_ident[2] != 'L' ||edhr.e_ident[3] != 'F')
    {
        printf("The opened file isn't a elf file!\n");
        exit(0);
    }
    
    fseek(fp, edhr.e_shoff, SEEK_SET);//读取elf段表

    Elf32_Shdr shdr;
    char *string_table = NULL;
    //寻找字符串表
    for(int i = 0; i < edhr.e_shnum; i++)//遍历段表
    {
        if(fread(&shdr, sizeof(Elf32_Shdr), 1, fp) <= 0)
        {
            printf("fail to read the shdr\n");
            exit(0);
        }
        
        if(shdr.sh_type == SHT_STRTAB)
        {
            //获取字符串表
            string_table = (char *)malloc(shdr.sh_size);
            fseek(fp, shdr.sh_offset, SEEK_SET);//将fp移动到字符串表起始位置
            if(fread(string_table, shdr.sh_size, 1, fp) <= 0)
            {
                printf("fail to read the strtab\n");
                exit(0);
            }
        }
    }
    number = 0;
    //寻找符号表
    fseek(fp, edhr.e_shoff, SEEK_SET);//将fp移动到段表起始位置
    
    for(int i = 0; i < edhr.e_shnum; i++)//遍历段表
    {
        if(fread(&shdr, sizeof(Elf32_Shdr), 1, fp) <= 0)
        {
            printf("fail to read the shdr\n");
            exit(0);
        }

        if(shdr.sh_type == SHT_SYMTAB)
        {
            fseek(fp, shdr.sh_offset, SEEK_SET);//将fp移动至符号表起始位置

            Elf32_Sym sym;
            int func_num = 0;
            size_t sym_count = shdr.sh_size / shdr.sh_entsize;//计算符号表中条目数量
            symbol = (Symbol *)malloc(sizeof(Symbol) * sym_count);

            for(size_t j = 0; j < sym_count; j++)//遍历每一个条目
            {
                if(fread(&sym, sizeof(Elf32_Sym), 1, fp) <= 0)
                {
                    printf("fail to read the symtab\n");
                    exit(0);
                }

                if(ELF32_ST_TYPE(sym.st_info) == STT_FUNC)//提出函数
                {
                    const char *name = string_table + sym.st_name;
                    strncpy(symbol[func_num].name, name, sizeof(symbol[func_num].name) - 1);
                    symbol[func_num].addr = sym.st_value;
                    symbol[func_num].size = sym.st_size;
                    func_num++;
                    number++;
                }
            }
        }
    }
    fclose(fp);
    free(string_table);
}
int depth=0;
void call_func(unsigned int pc,unsigned int dnpc){
    int i = 0;
    for(; i < number; i++)
    {
        if(dnpc >= symbol[i].addr && dnpc < (symbol[i].addr + symbol[i].size))
        {
            break;
        }
    }
    printf("0x%08x:", pc);
    
    for(int k = 0; k < depth; k++) printf("--");
    depth++;


    printf("call  [%s@0x%08x]\n", symbol[i].name, dnpc);

}
void ret_func(unsigned int pc){
    int i = 0;
    for(; i < number; i++){
        if(pc >= symbol[i].addr && pc < (symbol[i].addr + symbol[i].size)){
            break;
        }
    }
    printf("0x%08x:", pc);

    for(int k = 0; k < depth; k++) printf("--");
    depth--;
    printf("ret   [%s]\n", symbol[i].name);
}





