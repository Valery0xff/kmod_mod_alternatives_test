
#include <linux/kernel.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

char* mod_api1_func(char* rdata, size_t len)
{
	snprintf(rdata, len, "data from mod fb api1");
	rdata[len - 1] = 0x0;
	return rdata;
}

char* mod_api2_func(char* rdata, size_t len)
{
	snprintf(rdata, len, "data from mod fb api2");
	rdata[len - 1] = 0x0;
	return rdata;
}

EXPORT_SYMBOL(mod_api1_func);
EXPORT_SYMBOL(mod_api2_func);

int mod_fb_api12_init(void)
{
	pr_info("mod_fb_api12: init mod fb api12\n");
	return 0;
}

void mod_fb_api12_exit(void)
{
	pr_info("mod_fb_api12: Goodbye mod fb api12\n");
}

module_init(mod_fb_api12_init);
module_exit(mod_fb_api12_exit);

