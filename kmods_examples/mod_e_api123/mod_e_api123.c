
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/types.h>

MODULE_LICENSE("GPL");

char* mod_api1_func(char* rdata, size_t len)
{
	snprintf(rdata, len, "data from mod e api1");
	rdata[len - 1] = 0x0;
	return rdata;
}

char* mod_api2_func(char* rdata, size_t len)
{
	snprintf(rdata, len, "data from mod e api2");
	rdata[len - 1] = 0x0;
	return rdata;
}

uint32_t mod_api3_func(void)
{
	return 0xE003E003;
}

EXPORT_SYMBOL(mod_api1_func);
EXPORT_SYMBOL(mod_api2_func);
EXPORT_SYMBOL(mod_api3_func);

int mod_e_api123_init(void)
{
	pr_info("mod_e_api123: init mod e api123\n");
	return 0;
}

void mod_e_api123_exit(void)
{
	pr_info("mod_e_api123: Goodbye mod e api123\n");
}

module_init(mod_e_api123_init);
module_exit(mod_e_api123_exit);

