
#include <linux/kernel.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

extern char* mod_api1_func(char* rdata, size_t len);

int mod_h_dapi1_init(void)
{
	char api_data[128];
	pr_info("mod_h_dapi1: init mod_h default dependency on mod_b_api1\n");
	pr_info("mod_h_dapi1: data from api1 provider: %s\n", mod_api1_func(api_data, sizeof(api_data)));
	return 0;
}

void mod_h_dapi1_exit(void)
{
	pr_info("mod_h_dapi1: Goodbye mod_h default dependency on mod_b_api1\n");
}

module_init(mod_h_dapi1_init);
module_exit(mod_h_dapi1_exit);

