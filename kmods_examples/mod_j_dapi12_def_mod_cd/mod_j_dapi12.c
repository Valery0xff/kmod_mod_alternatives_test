
#include <linux/kernel.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

extern char* mod_api1_func(char* rdata, size_t len);
extern char* mod_api2_func(char* rdata, size_t len);

int mod_j_dapi12_init(void)
{
	char api_data[128];
	pr_info("mod_j_dapi12: init mod_j default dependency on mod_c_api1, mod_d_api2\n");
	pr_info("mod_j_dapi12: data from api1 provider: %s\n", mod_api1_func(api_data, sizeof(api_data)));
	pr_info("mod_j_dapi12: data from api2 provider: %s\n", mod_api2_func(api_data, sizeof(api_data)));
	return 0;
}

void mod_j_dapi12_exit(void)
{
	pr_info("mod_j_dapi12: Goodbye mod_j default dependency on mod_c_api1, mod_d_api2\n");
}

module_init(mod_j_dapi12_init);
module_exit(mod_j_dapi12_exit);

