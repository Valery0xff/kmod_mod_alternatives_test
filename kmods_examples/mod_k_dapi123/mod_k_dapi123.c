
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/types.h>

MODULE_LICENSE("GPL");

extern char* mod_api1_func(char* rdata, size_t len);
extern char* mod_api2_func(char* rdata, size_t len);
extern uint32_t mod_api3_func(void);

int mod_k_dapi123_init(void)
{
	char api_data[128];
	pr_info("mod_k_dapi123: init mod_k default dependency on mod_e_api123\n");
	pr_info("mod_k_dapi123: data from api1 provider: %s\n", mod_api1_func(api_data, sizeof(api_data)));
	pr_info("mod_k_dapi123: data from api2 provider: %s\n", mod_api2_func(api_data, sizeof(api_data)));
	pr_info("mod_k_dapi123: data from api3 provider: %x\n", mod_api3_func());
	return 0;
}

void mod_k_dapi123_exit(void)
{
	pr_info("mod_k_dapi123: Goodbye mod_k default dependency on mod_e_api123\n");
}

module_init(mod_k_dapi123_init);
module_exit(mod_k_dapi123_exit);

