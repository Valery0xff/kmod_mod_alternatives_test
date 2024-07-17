
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/types.h>

MODULE_LICENSE("GPL");

extern char* mod_api1_func(char* rdata, size_t len);
extern char* mod_api2_func(char* rdata, size_t len);
extern uint32_t mod_api3_func(void);
extern uint32_t mod_api4_func(void);

int mod_l_dapi1234_init(void)
{
	char api_data[128];
	pr_info("mod_l_dapi1234: init mod_l default dependencies on mod_fb_api12,mod_fc_api34\n");
	pr_info("mod_l_dapi1234: data from api1 provider: %s\n", mod_api1_func(api_data, sizeof(api_data)));
	pr_info("mod_l_dapi1234: data from api2 provider: %s\n", mod_api2_func(api_data, sizeof(api_data)));
	pr_info("mod_l_dapi1234: data from api3 provider: %x\n", mod_api3_func());
	pr_info("mod_l_dapi1234: data from api4 provider: %x\n", mod_api4_func());
	return 0;
}

void mod_l_dapi1234_exit(void)
{
	pr_info("mod_l_dapi1234: Goodbye mod_l default dependencies on mod_fb_api12,mod_fc_api34\n");
}

module_init(mod_l_dapi1234_init);
module_exit(mod_l_dapi1234_exit);

