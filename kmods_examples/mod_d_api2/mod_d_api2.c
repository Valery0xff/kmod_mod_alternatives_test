
#include <linux/kernel.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

char* mod_api2_func(char* rdata, size_t len)
{
	snprintf(rdata, len, "data from mod d api2");
	rdata[len - 1] = 0x0;
	return rdata;
}

EXPORT_SYMBOL(mod_api2_func);

int mod_d_api2_init(void)
{
	pr_info("mod_d_api2: init mod d api2\n");
	return 0;
}

void mod_d_api2_exit(void)
{
	pr_info("mod_d_api2: Goodbye mod d api2\n");
}

module_init(mod_d_api2_init);
module_exit(mod_d_api2_exit);

