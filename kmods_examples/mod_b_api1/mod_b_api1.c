
#include <linux/kernel.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

char* mod_api1_func(char* rdata, size_t len)
{
	snprintf(rdata, len, "data from mod b api1");
	rdata[len - 1] = 0x0;
	return rdata;
}

EXPORT_SYMBOL(mod_api1_func);

int mod_b_api1_init(void)
{
	pr_info("mod_b_api1: init mod b api1\n");
	return 0;
}

void mod_b_api1_exit(void)
{
	pr_info("mod_b_api1: Goodbye mod b api1\n");
}

module_init(mod_b_api1_init);
module_exit(mod_b_api1_exit);

