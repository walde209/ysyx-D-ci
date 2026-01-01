#include "sim.h"

IOMap maps[NR_MAP] = {};
int nr_map = 0;

static unsigned char *io_space = NULL;//base
static unsigned char *p_space = NULL;//current
void init_map() {
  io_space = (unsigned char *)malloc(IO_SPACE_MAX);
  assert(io_space);
  p_space = io_space;
}
unsigned char* new_space(int size) {
  unsigned char *p = p_space;
  // page aligned;
  size = (size + (PAGE_SIZE - 1)) & ~PAGE_MASK;
  p_space += size;
  assert(p_space - io_space < IO_SPACE_MAX);
  return p;
}
static void check_bound(IOMap *map, unsigned int addr) {
  if (map == NULL) {
    Log("address 0x%08x is out of bound ", addr);
    assert(0);
  } else {
    if(addr > map->high && addr < map->low){
        Log("address 0x%08x is out of bound {%s} [ 0x%08x ,  0x%08x ] ",addr, map->name, map->low, map->high);
        assert(0);
    }
  }
}

static void invoke_callback(io_callback_t c, unsigned int offset, int len, bool is_write) {
  if (c != NULL) { c(offset, len, is_write); }
}

static inline bool map_inside(IOMap *map, unsigned int addr) {
  return (addr >= map->low && addr <= map->high);
}
inline int find_mapid_by_addr(IOMap *maps, int size, unsigned int addr) {
  int i;
  for (i = 0; i < size; i ++) {
    if (map_inside(maps + i, addr)) {
      difftest_skip_ref();
      return i;
    }
  }
  return -1;
}
IOMap* fetch_mmio_map(unsigned int addr) {
  int mapid = find_mapid_by_addr(maps, nr_map, addr);
  return (mapid == -1 ? NULL : &maps[mapid]);
}

unsigned int map_read(unsigned int addr, int len, IOMap *map) {
  assert(len >= 1 && len <= 8);
  unsigned char *data_map=(unsigned char *)map->space;
  check_bound(map, addr);
  unsigned int offset = addr - map->low;
  invoke_callback(map->callback, offset, len, false); // prepare data to read
  unsigned int ret = host_read(data_map + offset);
  if(dtrace_flag){printf("\nmap_read %s at 0x%08x, data = %08x\n", map->name, addr, ret);}
  return ret;
}

void map_write(unsigned int addr, int len, unsigned int data, IOMap *map) {
  assert(len >= 1 && len <= 8);
  check_bound(map, addr);
  unsigned char *data_map = (unsigned char *)map->space;
  unsigned int offset = addr - map->low;
  host_write(data_map + offset, len, data);
  invoke_callback(map->callback, offset, len, true);
  if(dtrace_flag){printf("\nmap_write %s at 0x%08x, data = %08x\n", map->name, addr, data);}
}

void report_mmio_overlap(const char *name1, unsigned int l1, unsigned int r1,
    const char *name2, unsigned int l2, unsigned int r2) {
  Log("MMIO region %s@[ 0x%08x , 0x%08x ] is overlapped with %s@[ 0x%08x , 0x%08x ]", name1, l1, r1, name2, l2, r2);
}

void add_mmio_map(const char *name, unsigned int addr, void *space, unsigned int len, io_callback_t callback) {
  assert(nr_map < NR_MAP);
  unsigned int left = addr, right = addr + len - 1;
  if (in_pmem(left) || in_pmem(right)) {
    report_mmio_overlap(name, left, right, "pmem", PMEM_LEFT, PMEM_RIGHT);
  }
  for (int i = 0; i < nr_map; i++) {
    if (left <= maps[i].high && right >= maps[i].low) {
      report_mmio_overlap(name, left, right, maps[i].name, maps[i].low, maps[i].high);
    }
  }

  maps[nr_map] = (IOMap){ .name = name, .low = addr, .high = addr + len - 1,
    .space = space, .callback = callback };
  Log("Add mmio map '%s' at [ 0x%08x , 0x%08x ]",
      maps[nr_map].name, maps[nr_map].low, maps[nr_map].high);

  nr_map ++;
}