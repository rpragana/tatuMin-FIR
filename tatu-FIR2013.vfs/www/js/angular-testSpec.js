describe('filter',function(){
	beforeEach(module('myapp'));

	describe('reverse',function(){
		it('should reverse a string',inject(function(reverse){
			expect(reverse('ABCD')).toEqual('DCBA');
		}))
	})
})
