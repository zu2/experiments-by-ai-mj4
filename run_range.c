// usage: run_ms <mj4.raw> <trace.bin> [candidate-limit=4|5|6]
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "m6800.h"
#include SYMBOL_HEADER
static unsigned kind_old(unsigned k){return k<30?17+(k/10)*16+k%10:65+3*(k-30);}
static unsigned tile_old(unsigned t){return t==255?255:kind_old(t>>1)*2+(t&1);}
static uint8_t mem[65536], loaded[65536], keys[16];
static struct M68stat cpu;
static unsigned long cyc,nextirq,started,dt[4096]; static unsigned column;
static uint8_t startmem[65536];
typedef struct {unsigned id; uint16_t sp; unsigned long t;} Frame;
static Frame frames[128]; static unsigned nf;
static unsigned ntime,current_game; static uint16_t callsp; static int timing;
static unsigned intent_n, intent_count[5], yaku_count[64], wins; static int intent_pending;
uint8 m68read8(const struct M68stat*c,uint16 p){if(p==0xeec0)return 0xff^keys[column];if(p==0xef00)return 0xff;return c->m[p];}
uint16 m68read16(const struct M68stat*c,uint16 p){return ((uint16)m68read8(c,p)<<8)|m68read8(c,p+1);}
void m68write8(struct M68stat*c,uint16 p,uint8 v){if(p<0x100 && !(p>=0x72&&p<0xf2) && !(p>=0xa&&p<=0xc)){fprintf(stderr,"out-of-range low RAM write %04x at PC %04x\n",p,c->pc);exit(31);}if(p==0xeec0){column=v&15;return;}if(p==0xee80||p==0xefe0||p==0xe890||p==0xe892||p==0xee40)return;c->m[p]=v;}
void m68write16(struct M68stat*c,uint16 p,uint16 v){m68write8(c,p,v>>8);m68write8(c,p+1,v);}
static unsigned snapshots;static int last_ms=-2;
static int capture_mode;
static void step(void){
 if(cpu.wai||cyc>=nextirq){if(cyc<nextirq)cyc=nextirq;nextirq=cyc+12576;m68irq(&cpu);}
 int old=cpu.total_states;cpu.states=1;m68exec(&cpu);int d=cpu.total_states-old;cyc+=d>0?d:1;
}
static void until(unsigned p,unsigned long budget){while(budget--){if(cpu.pc==p)return;step();}fprintf(stderr,"timeout at %04x target %04x\n",cpu.pc,p);exit(2);}
static void init(void){memcpy(mem,loaded,sizeof mem);memset(keys,0,sizeof keys);cyc=0;nextirq=12576;ntime=0;timing=0;column=0;cpu=m68init(mem,NULL);cpu.pc=S_start;cpu.sp=0x3fff;cpu.cc=0;}
static void loadrom(const char*path){FILE*f=fopen(path,"rb");if(!f)exit(1);if(!fread(loaded+0x4000,1,0xa000,f))exit(1);fclose(f);
 uint8_t irq[]={0xb6,0xef,0,0x7c,0,0x0c,0x96,0x0c,0x81,0x3c,0x25,0x0b,0x7f,0,0x0c,0x7c,0,0x0b,0x26,3,0x7c,0,0x0a,0x3b};memcpy(loaded+0xf000,irq,sizeof irq);loaded[0xfff8]=0xf0;}
int main(int argc,char**argv){if(argc<4||argc>5)return 1;unsigned start_id=(unsigned)strtoul(argv[2],NULL,10),end_id=(unsigned)strtoul(argv[3],NULL,10);unsigned candidate_limit=4;if(argc==5){candidate_limit=(unsigned)strtoul(argv[4],NULL,10);if(candidate_limit<4||candidate_limit>6)return 1;}FILE*trace=fopen("/dev/null","wb");if(!trace)return 1;FILE*calls=fopen("/dev/null","wb");if(!calls)return 1;FILE*reactions=fopen("/dev/null","wb");if(!reactions)return 1;loadrom(argv[1]);
/* Verify both clearing ranges from poisoned RAM, before normal startup continues. */
init();memset(mem+0x72,0xa5,128);memset(mem+S_bss_start,0xa5,S_bss_all_end-S_bss_start);mem[0x71]=0x5a;mem[0xf2]=0xa6;
until(S_clear_directpage+8,10000000);
for(unsigned a=0x72;a<0xf2;a++)if(mem[a])return 32;
for(unsigned a=S_bss_start;a<S_bss_all_end;a++)if(mem[a])return 33;
if(mem[0x71]!=0x5a||mem[0xf2]!=0xa6)return 34;
fprintf(stderr,"PASS startup clear: DP 0072..00F1 and BSS; adjacent bytes preserved\n");
for(unsigned g=start_id;g<end_id;g++){
 init();until(S_title_wait,10000000);mem[S_cc_limit]=candidate_limit;mem[S_auto_play]=1;
 uint32_t seed=(g*0x9e3779b9u+0x7f4a7c15u)&0xffffffu;mem[S_seed]=seed;mem[S_seed+1]=seed>>8;mem[S_seed+2]=seed>>16;keys[11]=1;
 uint8_t reaction_hand[480];unsigned pending=0,reaction_p=0;
 unsigned long budget=3000000000UL,begin=0;unsigned phase=0,ended=0,turn=0;uint16_t sp=0;unsigned route=9,full=0,decision=0;
 while(budget--){
 if(cpu.pc==S_ai_call){memcpy(reaction_hand,mem+S_players,480);reaction_p=mem[S_ai_player];pending=1;}
 if(cpu.pc==S_react_answer && pending){uint32_t h[10]={g,decision,reaction_p,cpu.a,cpu.b,mem[S_dc_tile],mem[S_discarder],mem[S_draws_left],mem[S_round],mem[S_dealer]};pending=0;}

 if(cpu.pc==S_do_call){uint32_t h[10]={g,decision,mem[S_turn],mem[S_players+120*mem[S_turn]+52]+1,mem[S_react_act],mem[S_react_pat],mem[S_discarder],mem[S_dc_tile],mem[S_draws_left],0};}
 if(cpu.pc==S_ryukyoku||cpu.pc==S_settle_win){ended=cpu.pc==S_settle_win?1:2;break;}
 if(cpu.pc==S_cpu_turn&&!sp){last_ms=-2;sp=cpu.sp;begin=cyc;route=9;full=0;}
 if(cpu.pc==S_ai_discard){route=9;full=0;}
 if(cpu.pc==S_best_accept)route=1;
 if(cpu.pc==S_ev_discard)route=2;
 if(cpu.pc==S_least_danger)route=0;
 if(cpu.pc==S_choose_cands)full=1;
 if(cpu.pc==S_ai_discard_07){last_ms=(signed char)mem[S_min_s];unsigned p=mem[S_ai_player];uint32_t h[10]={g,decision++,p,mem[S_players+120*p+52]+1,route,full,0,mem[S_min_s],mem[S_ad_pick],mem[S_draws_left]};}
 if(sp&&mem[cpu.pc]==0x39&&cpu.sp==sp){printf("TURN,%u,%u,%u,%u,%u,%lu,%u\n",g,turn++,cpu.a,
(cpu.a==2?kind_old(cpu.b):cpu.a==0?tile_old(cpu.b):0),
mem[S_decl],cyc-begin+5,last_ms);sp=0;}
 if(cpu.pc==S_frame){phase^=1;memset(keys,0,sizeof keys);keys[11]=phase;}step();
 }
 if(!ended)return 3;printf("RESULT,%u,%u,%u,%u,%u,%u,%u\n",g,ended,mem[S_turn],mem[S_tsumo_flag],mem[S_best_han],mem[S_best_fu],mem[S_best_pts]*256+mem[S_best_pts+1]);
if(ended==1){printf("YAKU,%u,%u",g,mem[S_best_n]);for(unsigned yi=0;yi<mem[S_best_n];yi++)printf(",%u",mem[S_best_y+yi]);putchar('\n');}
 unsigned hash=2166136261u;
for(unsigned player=0;player<4;player++){
 unsigned a=S_players+120*player;unsigned char v[169]={0};
 for(unsigned k=0;k<37;k++)if(k!=9&&k!=19&&k!=29)v[kind_old(k)]=mem[a+k];
 memcpy(v+86,mem+a+37,83);
 v[87]=tile_old(v[87]);
 for(unsigned j=0;j<v[88];j++)v[90+j*3]=kind_old(v[90+j*3]);
 for(unsigned j=0;j<v[101];j++)v[102+j]=tile_old(v[102+j]);
 for(unsigned j=0;j<169;j++)hash=(hash^v[j])*16777619u;
}

 printf("END,%u,%u,%u,%u\n",g,ended,turn,hash);fflush(stdout);
}fclose(reactions);fclose(calls);fclose(trace);return 0;}
